import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> load() async {
    // Expects an ".env" file bundled as an asset (see pubspec.yaml)
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // Continue with nulls if not present in certain environments (e.g. CI)
    }
  }

  static String? get termsUrl => dotenv.maybeGet('TERMS_URL');
  static String? get privacyUrl => dotenv.maybeGet('PRIVACY_URL');

  // These are client-exposed keys and safe to ship in app builds.
  static String? get supabaseUrl => dotenv.maybeGet('SUPABASE_URL');
  static String? get supabaseAnonKey => dotenv.maybeGet('SUPABASE_ANON_KEY');

  // Analytics
  static String? get posthogKey => dotenv.maybeGet('POSTHOG_API_KEY');
  static String? get posthogHost => dotenv.maybeGet('POSTHOG_HOST');
}
