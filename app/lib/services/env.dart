import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

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

  // App data mode (supabase | firebase | mock)
  static String get dataMode => (dotenv.maybeGet('DATA_MODE') ?? 'supabase').toLowerCase();

  // Analytics
  static String? get mixpanelToken => dotenv.maybeGet('MIXPANEL_TOKEN');
  static String? get mixpanelHost => dotenv.maybeGet('MIXPANEL_HOST');

  // Gemini AI
  static String? get geminiApiKey => dotenv.maybeGet('GEMINI_API_KEY');

  // Firebase
  static String? get firebaseApiKey => dotenv.maybeGet('FIREBASE_API_KEY');
  static String? get firebaseAppId => dotenv.maybeGet('FIREBASE_APP_ID');
  static String? get firebaseMessagingSenderId => dotenv.maybeGet('FIREBASE_MESSAGING_SENDER_ID');
  static String? get firebaseProjectId => dotenv.maybeGet('FIREBASE_PROJECT_ID');
  static String? get firebaseStorageBucket => dotenv.maybeGet('FIREBASE_STORAGE_BUCKET');
  static String? get firebaseMeasurementId => dotenv.maybeGet('FIREBASE_MEASUREMENT_ID');

  static FirebaseOptions? get firebaseOptions {
    final apiKey = firebaseApiKey;
    final appId = firebaseAppId;
    final messagingSenderId = firebaseMessagingSenderId;
    final projectId = firebaseProjectId;

    if (apiKey == null || apiKey.isEmpty) return null;
    if (appId == null || appId.isEmpty) return null;
    if (messagingSenderId == null || messagingSenderId.isEmpty) return null;
    if (projectId == null || projectId.isEmpty) return null;

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: firebaseStorageBucket,
      measurementId: firebaseMeasurementId,
    );
  }
}
