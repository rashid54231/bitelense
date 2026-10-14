/// Application environment configuration reading from --dart-define.
/// Never hardcode secrets. Public keys and API base URLs are defined here.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mrngapmrvyukvkyuxfgi.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ybmdhcG1ydnl1a3ZreXV4ZmdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5NjIxMTUsImV4cCI6MjEwNzUzODExNX0.wyTbkXtZndX_qH9mivFff6FoIzc7mKxkn63KEk9gapw',
  );

  static const String revenuecatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: 'goog_placeholder',
  );

  static const String revenuecatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: 'appl_placeholder',
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://bitelens.app/privacy',
  );

  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://bitelens.app/terms',
  );

  static const String feedbackEmail = 'support@bitelens.app';

  /// Sanitize Supabase URL to strip trailing slash or /rest/v1 if present
  static String get cleanSupabaseUrl {
    var url = supabaseUrl.trim();
    if (url.endsWith('/rest/v1/')) {
      url = url.substring(0, url.length - 9);
    } else if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - 8);
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Check if Supabase keys are provided (not default placeholders)
  static bool get hasSupabaseConfig =>
      supabaseUrl != 'https://placeholder-project.supabase.co' &&
      supabaseAnonKey != 'placeholder-anon-key';

  /// Check if RevenueCat keys are configured
  static bool get hasRevenueCatConfig =>
      revenuecatAndroidKey != 'goog_placeholder' &&
      revenuecatIosKey != 'appl_placeholder';
}
