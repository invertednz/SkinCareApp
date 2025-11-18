import 'env.dart';

enum DataMode {
  supabase,
  firebase,
  mock,
}

class DataModeService {
  static DataMode get current {
    switch (Env.dataMode) {
      case 'firebase':
        return DataMode.firebase;
      case 'mock':
        return DataMode.mock;
      default:
        return DataMode.supabase;
    }
  }

  static bool get isSupabase => current == DataMode.supabase;
  static bool get isFirebase => current == DataMode.firebase;
  static bool get isMock => current == DataMode.mock;
}
