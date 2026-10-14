# BiteLens 🥗📸

> **Take a photo of your food and instantly get calories, protein, carbs and fat.**
> Built with high-precision recognition for South Asian (Desi) meals (Biryani, Karahi, Nihari, Daal, Roti, Naan, Paratha, Samosa, Chai) as well as global dishes.

---

## 📱 Features

- **Snap & Track:** Capture a plate with your camera or pick from gallery.
- **Desi & Global Food Vision:** Recognizes multiple dishes in one picture, estimating portion sizes, cooking oils, and nutritional density.
- **Interactive Editing & Rescaling:** Adjust grams or portion sizes with automatic proportional recalculation of calories and macros.
- **Mifflin-St Jeor Engine:** Personalized daily calorie goals based on sex, height, weight, age, activity level, and weight goals (clamped to a safe 1200 kcal floor).
- **Today Dashboard:** Animated circular calorie ring, macro distribution chips, recent meal logs grouped by meal type.
- **History & Pro Insights:** Calendar day-by-day logs, 7-day intake bar charts, macro splits, and streak counters.
- **Fair Monetization:** Free users get 3 successful scans per local day. Pro users enjoy unlimited scans, lifetime history, and advanced trends.
- **Dark-First Glassmorphic Design:** Polished animations, theme switcher (Dark / Light / System), offline monitoring, and accessibility touch targets.

---

## 🛠 Tech Stack

- **Frontend:** Flutter (v3.44+), Dart 3.12+ (Sound null safety)
- **State Management:** Riverpod (Notifier / AsyncNotifier)
- **Navigation:** go_router with auth-aware redirect
- **Backend:** Supabase (Auth, Postgres, Row Level Security, Storage, Edge Functions)
- **AI Engine:** Google Gemini Vision via Supabase Edge Function (`GEMINI_MODEL`)
- **Subscriptions:** RevenueCat (`purchases_flutter`)

---

## 🚀 Quick Setup Guide

### 1. Supabase Database & Storage Setup
You can set up your Supabase backend in **less than 2 minutes** using the all-in-one SQL script:

1. Log into your [Supabase Dashboard](https://supabase.com).
2. Go to **SQL Editor** -> **New Query**.
3. Open the file [`supabase/all_in_one_backend.sql`](./supabase/all_in_one_backend.sql).
4. Copy its entire content, paste it into the SQL Editor, and click **Run**.
5. This automatically creates:
   - `profiles`, `meals`, `daily_usage`, and `subscriptions` tables.
   - All Row-Level Security (RLS) policies.
   - Triggers for user profile creation.
   - The security-definer function `increment_scan_usage`.
   - The private storage bucket `meal-photos` with folder ownership rules.

---

### 2. Supabase Edge Functions Deployment

Deploy the edge functions using the Supabase CLI:

```bash
# Login to Supabase CLI
supabase login

# Link your local project
supabase link --project-ref your-supabase-project-ref

# Set server-side secrets
supabase secrets set GEMINI_API_KEY="your_gemini_api_key_here"
supabase secrets set GEMINI_MODEL="gemini-1.5-flash"
supabase secrets set FREE_DAILY_LIMIT="3"
supabase secrets set REVENUECAT_WEBHOOK_SECRET="your_shared_webhook_secret"
supabase secrets set MOCK_AI="false"

# Deploy functions
supabase functions deploy analyze-meal
supabase functions deploy revenuecat-webhook
supabase functions deploy delete-account
```

> **Testing without Gemini API Key:** Set `MOCK_AI="true"` in secrets. The app will return realistic South Asian meal results (Biryani, Raita, Salad) without calling external AI APIs.

---

### 3. Google OAuth Redirect Configuration

In your Supabase Dashboard:
1. Navigate to **Authentication** -> **URL Configuration**.
2. Under **Redirect URLs**, add:
   ```
   com.bitelens.app://login-callback
   com.bitelens.app://reset-callback
   ```

---

### 4. RevenueCat Setup

1. In [RevenueCat](https://app.revenuecat.com):
   - Create a project named `BiteLens`.
   - Add Android (Google Play) and iOS (App Store) apps.
   - Create an Entitlement named `pro`.
   - Create two products (e.g. `bitelens_monthly` and `bitelens_annual`) and attach them to the `pro` entitlement.
   - Create a default Offering named `default` with **Monthly** and **Annual** packages.
2. In RevenueCat **Integrations** -> **Webhooks**:
   - Webhook URL: `https://<your-project-ref>.supabase.co/functions/v1/revenuecat-webhook`
   - Authorization Header: Enter your secret (must match `REVENUECAT_WEBHOOK_SECRET`).

---

### 5. Running the Flutter App

Copy `env.example.json` to `env.json` and fill in your keys:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-supabase-anon-key",
  "REVENUECAT_ANDROID_KEY": "goog_your_key",
  "REVENUECAT_IOS_KEY": "appl_your_key",
  "PRIVACY_POLICY_URL": "https://bitelens.app/privacy",
  "TERMS_URL": "https://bitelens.app/terms"
}
```

Run with:

```bash
flutter run --dart-define-from-file=env.json
```

Or pass variables directly via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-supabase-anon-key" \
  --dart-define=REVENUECAT_ANDROID_KEY="goog_your_key" \
  --dart-define=REVENUECAT_IOS_KEY="appl_your_key"
```

---

### 6. Building Release Artifacts

#### Android (Release APK & App Bundle):
```bash
flutter build apk --release --dart-define-from-file=env.json
flutter build appbundle --release --dart-define-from-file=env.json
```

#### iOS (Release IPA):
```bash
flutter build ipa --release --dart-define-from-file=env.json
```

---

## 🧪 Testing

Run all unit & widget tests:
```bash
flutter test
```

Run Deno edge functions tests:
```bash
deno test supabase/functions/tests/edge_functions_test.ts
```

---

## 🛡 Privacy & Disclaimer

AI calorie counts are estimations and are intended for general nutritional awareness, not medical advice.
Photos are stored privately in user-segregated storage folders and are used solely for nutritional analysis.
Users can permanently remove their accounts and all associated data at any time via **Settings -> Delete Account**.
