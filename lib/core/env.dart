import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads config from .env file first, falls back to --dart-define values.
/// This allows the app to work both from Android Studio (reads .env)
/// and from CLI with --dart-define flags.
class Env {
  Env._();

  static String get(String key, {String defaultValue = ''}) {
    final fromDotenv = dotenv.env[key];
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    return String.fromEnvironment(key, defaultValue: defaultValue);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    final value = get(key, defaultValue: defaultValue.toString());
    return value.toLowerCase() == 'true';
  }

  static bool get useSupabase => getBool('USE_SUPABASE_EXPLORER');
  static String get workspaceId => get('FILEZEN_WORKSPACE_ID');
  static String get dbSchema => get('FILEZEN_DB_SCHEMA', defaultValue: 'app');
  static String get supabaseUrl => get('SUPABASE_URL');
  static String get supabaseAnonKey => get('SUPABASE_ANON_KEY');
}
