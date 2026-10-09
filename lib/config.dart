/// Build-time config. Pass with --dart-define, for example:
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
/// Without them, the app runs offline: solo play and daily facts only.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get onlineEnabled => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
