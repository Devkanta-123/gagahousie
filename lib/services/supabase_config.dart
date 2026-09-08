/// Supabase Configuration & Credentials
///
/// To connect to your Supabase project:
/// 1. Replace [supabaseUrl] with your Supabase Project URL (from Supabase Dashboard -> Settings -> API).
/// 2. Replace [supabaseAnonKey] with your Supabase anon/public API key.
/// 3. Create the `user_auth` table in your Supabase SQL Editor.
class SupabaseConfig {
  /// Supabase Project URL (e.g., https://your-project-id.supabase.co)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue:
        'https://jwprioijhxyhqmfhqdng.supabase.co', // Replace with your Supabase Project URL
  );

  /// Supabase Public Anon Key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_aQ2pKZfHTUY0Mp-3MCetGA_XmiYjZOv', // Replace with your Supabase Anon Key
  );

  /// Database Table Name for Authentication
  static const String userAuthTable = 'user_auth';

  /// Column Names in the `user_auth` table
  static const String colId = 'id';
  static const String colFullName = 'fullname';
  static const String colEmail = 'email';
  static const String colPhone = 'phone';
  static const String colPassword = 'password';
  static const String colStatus = 'status';
  static const String colRole = 'role';
  static const String colCreatedAt = 'created_at';

  /// Runtime override options if user sets them programmatically
  static String? _customUrl;
  static String? _customAnonKey;

  static void setCredentials({required String url, required String anonKey}) {
    _customUrl = url;
    _customAnonKey = anonKey;
  }

  static String get activeUrl => _customUrl ?? supabaseUrl;
  static String get activeAnonKey => _customAnonKey ?? supabaseAnonKey;

  /// Returns true if valid custom or environment credentials have been set
  static bool get isConfigured {
    final url = activeUrl;
    final key = activeAnonKey;
    return url.isNotEmpty &&
        !url.contains('xyzcompany.supabase.co') &&
        key.isNotEmpty &&
        !key.contains('dummy_anon_key');
  }
}
