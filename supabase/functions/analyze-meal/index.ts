import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { handleCors } from '../_shared/cors.ts';
import { jsonResponse, errorResponse } from '../_shared/responses.ts';
import { verifyAuth } from '../_shared/auth.ts';

interface MealItem {
  name: string;
  portion_text: string;
  grams_estimate: number;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  fiber_g: number;
}

interface AiResponse {
  is_food: boolean;
  dish_summary: string;
  confidence: 'high' | 'medium' | 'low';
  items: MealItem[];
}

const SYSTEM_PROMPT = `You are a nutrition analyst for a food-photo app. Look at the photo and identify every distinct food and drink item. Many photos are South Asian (Pakistani/Indian/Bangladeshi) home or restaurant meals; correctly recognize dishes such as biryani, pulao, karahi, handi, nihari, haleem, daal (masoor, mash, chana), sabzi, aloo gobi, roti/chapati/naan/paratha, raita, salad, kebabs, samosa, pakora, halwa, kheer, chai, lassi. Use the most specific common name. For each item, estimate the portion in grams or a household measure using visible cues (plate size, hand, cutlery, bowl size), then estimate calories, protein, carbs, fat and fiber for that portion. Account for typical cooking oil/ghee in home and restaurant cooking. If the photo is not food (a person, object, screenshot, empty plate), set is_food to false. Give an overall confidence: high, medium or low (low if the image is blurry, dark, or the portion is hard to judge). Return ONLY valid JSON matching the schema. Never include medical advice.`;

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    // 1. Verify User
    let authContext;
    try {
      authContext = await verifyAuth(req);
    } catch {
      return errorResponse('UNAUTHORIZED', 'Missing or invalid token.', 401);
    }
    const { user, adminClient } = authContext;

    // Parse Body
    const body = await req.json().catch(() => ({}));
    const { image_path, meal_type = 'lunch', tz = 'UTC' } = body;

    if (!image_path || typeof image_path !== 'string') {
      return errorResponse('INVALID_INPUT', 'image_path is required.');
    }

    // 2. Verify Path Ownership
    if (!image_path.startsWith(`${user.id}/`)) {
      return errorResponse('FORBIDDEN', 'You may only analyze your own photos.', 403);
    }

    // 3. Determine Pro Status
    const { data: subData } = await adminClient
      .from('subscriptions')
      .select('is_pro, expires_at')
      .eq('user_id', user.id)
      .maybeSingle();

    const isPro =
      subData?.is_pro === true &&
      (!subData.expires_at || new Date(subData.expires_at) > new Date());

    // 4. Calculate local date from timezone and enforce free quota
    let localDateStr: string;
    try {
      const now = new Date();
      localDateStr = new Intl.DateTimeFormat('en-CA', {
        timeZone: tz,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      }).format(now);
    } catch {
      localDateStr = new Date().toISOString().split('T')[0];
    }

    const freeLimit = parseInt(Deno.env.get('FREE_DAILY_LIMIT') || '3', 10);

    if (!isPro) {
      const { data: usage } = await adminClient
        .from('daily_usage')
        .select('scan_count')
        .eq('user_id', user.id)
        .eq('usage_date', localDateStr)
        .maybeSingle();

      const currentCount = usage?.scan_count || 0;
      if (currentCount >= freeLimit) {
        return errorResponse(
          'LIMIT_REACHED',
          'You have reached your 3 free scans for today. Upgrade to Pro for unlimited scans.',
          429
        );
      }
    }

    // 5. Check if Mock AI mode is enabled
    const isMock = Deno.env.get('MOCK_AI') === 'true';
    let analysisResult: AiResponse;

    if (isMock) {
      analysisResult = {
        is_food: true,
        dish_summary: 'Chicken Biryani with Fresh Salad and Raita',
        confidence: 'high',
        items: [
          {
            name: 'Chicken Biryani',
            portion_text: '1 plate / 350g',
            grams_estimate: 350,
            calories: 560,
            protein_g: 34,
            carbs_g: 68,
            fat_g: 17,
            fiber_g: 3.5,
          },
          {
            name: 'Cucumber Mint Raita',
            portion_text: '1 small bowl / 100g',
            grams_estimate: 100,
            calories: 75,
            protein_g: 3.2,
            carbs_g: 4.5,
            fat_g: 4.8,
            fiber_g: 0.5,
          },
          {
            name: 'Fresh Salad',
            portion_text: '1 side serving',
            grams_estimate: 80,
            calories: 25,
            protein_g: 1.0,
            carbs_g: 5.0,
            fat_g: 0.2,
            fiber_g: 2.0,
          },
        ],
      };
    } else {
      // 6. Download image from Storage
      const { data: fileData, error: downloadError } = await adminClient.storage
        .from('meal-photos')
        .download(image_path);

      if (downloadError || !fileData) {
        return errorResponse('STORAGE_ERROR', 'Could not read image from storage.', 404);
      }

      // Check max file size (5MB)
      if (fileData.size > 5 * 1024 * 1024) {
        return errorResponse('FILE_TOO_LARGE', 'Image exceeds 5MB size limit.');
      }

      const arrayBuffer = await fileData.arrayBuffer();
      const base64Image = btoa(
        new Uint8Array(arrayBuffer).reduce((data, byte) => data + String.fromCharCode(byte), '')
      );

      // 7. Call Gemini Vision API
      const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
      const geminiModel = Deno.env.get('GEMINI_MODEL') || 'gemini-1.5-flash';

      if (!geminiApiKey) {
        return errorResponse('CONFIG_ERROR', 'Gemini API key is not configured on the server.', 500);
      }

      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`;

      const geminiPayload = {
        contents: [
          {
            role: 'user',
            parts: [
              { text: SYSTEM_PROMPT },
              {
                inlineData: {
                  mimeType: 'image/jpeg',
                  data: base64Image,
                },
              },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.2,
        },
      };

      // Call with 40s timeout and 1 retry
      let geminiRes: Response | null = null;
      for (let attempt = 0; attempt < 2; attempt++) {
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 40000);

          geminiRes = await fetch(geminiUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(geminiPayload),
            signal: controller.signal,
          });

          clearTimeout(timeoutId);
          if (geminiRes.ok) break;
        } catch (_) {
          if (attempt === 1) throw new Error('AI_TIMEOUT');
        }
      }

      if (!geminiRes || !geminiRes.ok) {
        return errorResponse('AI_BAD_RESPONSE', 'Gemini AI service error. Please retry.', 502);
      }

      const geminiJson = await geminiRes.json();
      const textCandidate =
        geminiJson.candidates?.[0]?.content?.parts?.[0]?.text || '';

      // Parse JSON strictly
      try {
        analysisResult = JSON.parse(textCandidate);
      } catch {
        return errorResponse('AI_BAD_RESPONSE', 'Invalid JSON from AI model.', 502);
      }
    }

    // 8. Handle Not Food
    if (!analysisResult.is_food) {
      return errorResponse('NOT_FOOD', 'No food recognized in photo. Scan not counted.', 422);
    }

    // 9. Strict Validation of Items
    if (!Array.isArray(analysisResult.items) || analysisResult.items.length === 0) {
      return errorResponse('AI_BAD_RESPONSE', 'No food items identified.', 502);
    }

    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;
    let totalFiber = 0;

    const validatedItems: MealItem[] = [];
    for (const item of analysisResult.items) {
      const cal = Math.max(0, Math.min(3000, Number(item.calories) || 0));
      const p = Math.max(0, Math.min(300, Number(item.protein_g) || 0));
      const c = Math.max(0, Math.min(500, Number(item.carbs_g) || 0));
      const f = Math.max(0, Math.min(300, Number(item.fat_g) || 0));
      const fib = Math.max(0, Math.min(100, Number(item.fiber_g) || 0));

      totalCalories += cal;
      totalProtein += p;
      totalCarbs += c;
      totalFat += f;
      totalFiber += fib;

      validatedItems.push({
        name: String(item.name || 'Dish item').slice(0, 100),
        portion_text: String(item.portion_text || '1 portion').slice(0, 100),
        grams_estimate: Math.max(1, Math.min(2000, Number(item.grams_estimate) || 100)),
        calories: Math.round(cal),
        protein_g: Math.round(p * 10) / 10,
        carbs_g: Math.round(c * 10) / 10,
        fat_g: Math.round(f * 10) / 10,
        fiber_g: Math.round(fib * 10) / 10,
      });
    }

    // 10. Increment Daily Scan Usage atomically via security definer function
    await adminClient.rpc('increment_scan_usage', {
      p_user: user.id,
      p_date: localDateStr,
    });

    return jsonResponse({
      ok: true,
      data: {
        is_food: true,
        dish_summary: analysisResult.dish_summary || validatedItems.map((i) => i.name).join(', '),
        confidence: analysisResult.confidence || 'medium',
        items: validatedItems,
        total_calories: Math.round(totalCalories),
        total_protein_g: Math.round(totalProtein * 10) / 10,
        total_carbs_g: Math.round(totalCarbs * 10) / 10,
        total_fat_g: Math.round(totalFat * 10) / 10,
        total_fiber_g: Math.round(totalFiber * 10) / 10,
        image_path,
        meal_type,
      },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown server error';
    return errorResponse('INTERNAL_ERROR', message, 500);
  }
});
