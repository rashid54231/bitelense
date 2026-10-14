import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';
import { handleCors } from '../_shared/cors.ts';
import { jsonResponse, errorResponse } from '../_shared/responses.ts';

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== 'POST') {
    return errorResponse('METHOD_NOT_ALLOWED', 'Only POST is supported', 405);
  }

  // 1. Verify Secret in Authorization Header
  const secret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET');
  const authHeader = req.headers.get('Authorization') || req.headers.get('X-RevenueCat-Secret');

  if (!secret || authHeader !== secret) {
    return errorResponse('UNAUTHORIZED', 'Invalid or missing webhook secret.', 401);
  }

  try {
    const payload = await req.json();
    const event = payload.event;

    if (!event) {
      return errorResponse('BAD_REQUEST', 'Missing event in payload.', 400);
    }

    const {
      type,
      app_user_id,
      product_id,
      entitlement_ids,
      expiration_at_ms,
      store,
    } = event;

    if (!app_user_id) {
      return errorResponse('BAD_REQUEST', 'Missing app_user_id.', 400);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    const expiresAt = expiration_at_ms ? new Date(expiration_at_ms).toISOString() : null;
    const entitlement = Array.isArray(entitlement_ids) ? entitlement_ids[0] : 'pro';

    let isPro = false;

    switch (type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'PRODUCT_CHANGE':
      case 'UNCANCELLATION':
      case 'NON_RENEWING_PURCHASE':
        isPro = true;
        break;

      case 'CANCELLATION':
      case 'BILLING_ISSUE':
        // Keep active until expiration_at_ms
        if (expiration_at_ms && expiration_at_ms > Date.now()) {
          isPro = true;
        } else {
          isPro = false;
        }
        break;

      case 'EXPIRATION':
      case 'REVOCATION':
        isPro = false;
        break;

      default:
        // Ignore unhandled events with ok response
        return jsonResponse({ ok: true, message: `Event ${type} ignored.` });
    }

    // Idempotent upsert into subscriptions table
    const { error: upsertError } = await adminClient
      .from('subscriptions')
      .upsert({
        user_id: app_user_id,
        is_pro: isPro,
        entitlement: entitlement,
        product_id: product_id || null,
        store: store || null,
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      });

    if (upsertError) {
      console.error('Error updating subscription:', upsertError);
      return errorResponse('DB_ERROR', 'Failed to update subscription record.', 500);
    }

    return jsonResponse({
      ok: true,
      data: {
        user_id: app_user_id,
        is_pro: isPro,
        event_type: type,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Webhook error';
    return errorResponse('INTERNAL_ERROR', msg, 500);
  }
});
