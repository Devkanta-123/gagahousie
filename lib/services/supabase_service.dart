import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import 'supabase_config.dart';

/// Result object describing the Supabase connection check
class SupabaseConnectionResult {
  final bool success;
  final String message;
  final bool tableReady;
  final String? errorDetails;

  const SupabaseConnectionResult({
    required this.success,
    required this.message,
    this.tableReady = false,
    this.errorDetails,
  });
}

/// Custom exception for authentication and Supabase operations
class SupabaseAuthException implements Exception {
  final String message;
  const SupabaseAuthException(this.message);

  @override
  String toString() => message;
}

/// Singleton service handling Supabase connection and user_auth table operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;

  SupabaseService._internal();

  bool _isInitialized = false;
  bool _isConnected = false;
  String _lastConnectionMessage = 'Not connected';

  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String get lastConnectionMessage => _lastConnectionMessage;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Supabase with configured credentials
  Future<void> initialize({String? customUrl, String? customAnonKey}) async {
    if (customUrl != null && customAnonKey != null) {
      SupabaseConfig.setCredentials(url: customUrl, anonKey: customAnonKey);
    }

    final url = SupabaseConfig.activeUrl;
    final anonKey = SupabaseConfig.activeAnonKey;

    debugPrint('==================================================');
    debugPrint('🔌 [SUPABASE] Initializing Supabase Connection...');
    debugPrint('🌐 [SUPABASE] Project URL: $url');

    if (!SupabaseConfig.isConfigured) {
      debugPrint(
          '⚠️ [SUPABASE NOTICE] Using placeholder Supabase credentials.');
      debugPrint('⚠️ To connect to your Supabase project, update:');
      debugPrint('⚠️   lib/services/supabase_config.dart');
      debugPrint('⚠️ (Login system is operational in demo/fallback mode).');
      debugPrint('==================================================');
      _isInitialized = false;
      _isConnected = false;
      _lastConnectionMessage =
          'Credentials not configured yet in supabase_config.dart';
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;

      // Test connection immediately and print status
      await testConnection();
    } catch (e) {
      _isInitialized = false;
      _isConnected = false;
      _lastConnectionMessage = 'Initialization failed: $e';
      debugPrint('❌ [SUPABASE INIT ERROR]: $e');
      debugPrint('==================================================');
    }
  }

  /// Test connection to Supabase and verify the `user_auth` table
  Future<SupabaseConnectionResult> testConnection() async {
    if (!SupabaseConfig.isConfigured || !_isInitialized) {
      const msg =
          'Supabase credentials are not configured in supabase_config.dart';
      debugPrint('ℹ️ [SUPABASE STATUS] $msg');
      return SupabaseConnectionResult(
        success: false,
        message: msg,
        tableReady: false,
      );
    }

    try {
      final currentClient = client;
      if (currentClient == null) {
        throw Exception('Supabase client is not available');
      }

      // Query table user_auth to verify connection and schema
      await currentClient
          .from(SupabaseConfig.userAuthTable)
          .select(SupabaseConfig.colFullName)
          .limit(1);

      _isConnected = true;
      _lastConnectionMessage =
          'Connected successfully to Supabase. Table "${SupabaseConfig.userAuthTable}" is ready.';

      debugPrint('==================================================');
      debugPrint('✅ [SUPABASE CONNECTION SUCCESSFUL]');
      debugPrint('✅ Successfully connected to Supabase for login system!');
      debugPrint('✅ Project URL: ${SupabaseConfig.activeUrl}');
      debugPrint(
          '✅ Authentication Table: "${SupabaseConfig.userAuthTable}" is verified & accessible.');
      debugPrint('==================================================');

      return SupabaseConnectionResult(
        success: true,
        message: _lastConnectionMessage,
        tableReady: true,
      );
    } on PostgrestException catch (pe) {
      // If table doesn't exist yet, missing in schema cache (PGRST205), or permission issue
      if (pe.code == '42P01' ||
          pe.code == 'PGRST205' ||
          pe.message.contains('does not exist') ||
          pe.message.contains('schema cache')) {
        _isConnected = true;
        _lastConnectionMessage =
            'Connected to Supabase! Table "${SupabaseConfig.userAuthTable}" needs to be created in Supabase SQL Editor.';
        debugPrint('==================================================');
        debugPrint('🔌 [SUPABASE PROJECT CONNECTED]');
        debugPrint('⚠️ [TABLE NOT FOUND IN SCHEMA CACHE: PGRST205]');
        debugPrint('🌐 Connected to: ${SupabaseConfig.activeUrl}');
        debugPrint(
            '📋 The table "${SupabaseConfig.userAuthTable}" has not been created yet.');
        debugPrint(
            '👉 Please run supabase_schema.sql in your Supabase SQL Editor to create it.');
        debugPrint('==================================================');
        return SupabaseConnectionResult(
          success: true,
          message: _lastConnectionMessage,
          tableReady: false,
          errorDetails: pe.message,
        );
      }

      _isConnected = false;
      _lastConnectionMessage = 'Postgrest error (${pe.code}): ${pe.message}';
      debugPrint(
          '❌ [SUPABASE QUERY ERROR] Code: ${pe.code}, Details: ${pe.message}');
      return SupabaseConnectionResult(
        success: false,
        message: _lastConnectionMessage,
        tableReady: false,
        errorDetails: pe.message,
      );
    } catch (e) {
      _isConnected = false;
      _lastConnectionMessage = 'Connection failed: $e';
      debugPrint('❌ [SUPABASE CONNECTION FAILED] Details: $e');
      return SupabaseConnectionResult(
        success: false,
        message: _lastConnectionMessage,
        tableReady: false,
        errorDetails: e.toString(),
      );
    }
  }

  /// Authenticate user against `user_auth` table
  /// [identifier] can be an email address OR a 10-digit phone number
  Future<UserModel> authenticate({
    required String identifier,
    required String password,
  }) async {
    // 1. Validation
    final identifierError = AuthValidator.validateLoginIdentifier(identifier);
    if (identifierError != null) {
      throw SupabaseAuthException(identifierError);
    }
    final passwordError = AuthValidator.validatePassword(password);
    if (passwordError != null) {
      throw SupabaseAuthException(passwordError);
    }

    final trimmedIdentifier = identifier.trim();
    final isPhoneInput = AuthValidator.isPhone(trimmedIdentifier);
    final cleanPhone = AuthValidator.cleanPhone(trimmedIdentifier);
    final cleanEmail = trimmedIdentifier.toLowerCase();

    debugPrint('--------------------------------------------------');
    debugPrint('🔐 [SUPABASE LOGIN] Connection check for login system...');
    debugPrint('🔐 [SUPABASE LOGIN] Attempting login with: $trimmedIdentifier');
    debugPrint(
        '🔐 [SUPABASE LOGIN] Target Table: "${SupabaseConfig.userAuthTable}"');

    // Strict DB Table Check
    if (!SupabaseConfig.isConfigured || !_isInitialized) {
      debugPrint('❌ [SUPABASE LOGIN] Supabase is not connected to DB.');
      throw const SupabaseAuthException(
        'Supabase database is not connected. Please verify your internet connection.',
      );
    }

    // 2. Query Supabase `user_auth` table
    try {
      final currentClient = client;
      if (currentClient == null) {
        throw const SupabaseAuthException('Supabase client is not ready');
      }

      var query = currentClient.from(SupabaseConfig.userAuthTable).select();

      if (isPhoneInput) {
        query = query.eq(SupabaseConfig.colPhone, cleanPhone);
      } else {
        query = query.eq(SupabaseConfig.colEmail, cleanEmail);
      }

      final response =
          await query.eq(SupabaseConfig.colPassword, password).maybeSingle();

      if (response == null) {
        debugPrint(
            '❌ [SUPABASE LOGIN FAILED] No matching account found for: $trimmedIdentifier');
        debugPrint('--------------------------------------------------');
        throw const SupabaseAuthException(
            'Invalid email/phone or password. Please check your credentials.');
      }

      final user = UserModel.fromJson(response);
      debugPrint('==================================================');
      debugPrint('✅ [SUPABASE LOGIN SUCCESSFUL]');
      debugPrint(
          '✅ Successfully authenticated user from "${SupabaseConfig.userAuthTable}"!');
      debugPrint('✅ Full Name : ${user.fullName}');
      debugPrint('✅ Email     : ${user.email}');
      debugPrint('✅ Phone     : ${user.phone}');
      debugPrint('✅ Status    : ${user.status}');
      debugPrint('✅ Role      : ${user.role}');
      debugPrint('==================================================');

      if (!user.isActive) {
        debugPrint(
            '⚠️ [SUPABASE LOGIN BLOCKED] Account status is "${user.status}" for $trimmedIdentifier');
        throw SupabaseAuthException(
          'Your account is currently ${user.status}. Please contact support.',
        );
      }

      return user;
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST205' ||
          pe.message.contains('schema cache') ||
          pe.message.contains('does not exist')) {
        debugPrint(
            '❌ [SUPABASE AUTH] Table "${SupabaseConfig.userAuthTable}" not found in schema cache (PGRST205).');
        debugPrint(
            '👉 Please execute supabase_schema.sql in your Supabase SQL Editor.');
        throw const SupabaseAuthException(
          'Table "user_auth" does not exist in your Supabase database yet. Please run supabase_schema.sql in Supabase SQL Editor.',
        );
      }
      debugPrint(
          '❌ [SUPABASE POSTGREST ERROR] Code: ${pe.code}, Details: ${pe.message}');
      throw SupabaseAuthException('Database error: ${pe.message}');
    } on SupabaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [SUPABASE AUTH ERROR] $e');
      throw SupabaseAuthException('Authentication error: ${e.toString()}');
    }
  }

  /// Register a new user into `user_auth` table
  /// Required columns: fullname, email, phone (10 digits), password
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    // 1. Strict Validations
    final nameError = AuthValidator.validateFullName(fullName);
    if (nameError != null) throw SupabaseAuthException(nameError);

    final emailError = AuthValidator.validateEmail(email);
    if (emailError != null) throw SupabaseAuthException(emailError);

    final phoneError = AuthValidator.validatePhone(phone);
    if (phoneError != null) throw SupabaseAuthException(phoneError);

    final passwordError = AuthValidator.validatePassword(password);
    if (passwordError != null) throw SupabaseAuthException(passwordError);

    final cleanName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = AuthValidator.cleanPhone(phone);

    debugPrint('--------------------------------------------------');
    debugPrint(
        '📝 [SUPABASE REGISTER] Starting registration in table "${SupabaseConfig.userAuthTable}"...');
    debugPrint('📝 [SUPABASE REGISTER] Name : $cleanName');
    debugPrint('📝 [SUPABASE REGISTER] Email: $cleanEmail');
    debugPrint('📝 [SUPABASE REGISTER] Phone: $cleanPhone (10 digits)');

    // Strict DB Table Check
    if (!SupabaseConfig.isConfigured || !_isInitialized) {
      debugPrint('❌ [SUPABASE REGISTER] Supabase is not connected to DB.');
      throw const SupabaseAuthException(
        'Supabase database is not connected. Please verify your internet connection.',
      );
    }

    try {
      final currentClient = client;
      if (currentClient == null) {
        throw const SupabaseAuthException('Supabase client is not initialized');
      }

      // 2. Check if email already exists
      final existingEmail = await currentClient
          .from(SupabaseConfig.userAuthTable)
          .select(SupabaseConfig.colEmail)
          .eq(SupabaseConfig.colEmail, cleanEmail)
          .maybeSingle();

      if (existingEmail != null) {
        debugPrint(
            '⚠️ [SUPABASE REGISTER] Email already registered: $cleanEmail');
        throw const SupabaseAuthException(
            'An account with this email address already exists.');
      }

      // 3. Check if phone already exists
      final existingPhone = await currentClient
          .from(SupabaseConfig.userAuthTable)
          .select(SupabaseConfig.colPhone)
          .eq(SupabaseConfig.colPhone, cleanPhone)
          .maybeSingle();

      if (existingPhone != null) {
        debugPrint(
            '⚠️ [SUPABASE REGISTER] Phone already registered: $cleanPhone');
        throw const SupabaseAuthException(
            'An account with this 10-digit mobile number already exists.');
      }

      // 4. Insert row into `user_auth` table
      final insertData = {
        SupabaseConfig.colFullName: cleanName,
        SupabaseConfig.colEmail: cleanEmail,
        SupabaseConfig.colPhone: cleanPhone,
        SupabaseConfig.colPassword: password,
        SupabaseConfig.colStatus: 'active',
        SupabaseConfig.colRole: 'user',
      };

      final response = await currentClient
          .from(SupabaseConfig.userAuthTable)
          .insert(insertData)
          .select()
          .single();

      final newUser = UserModel.fromJson(response);

      debugPrint('==================================================');
      debugPrint('✅ [SUPABASE REGISTER SUCCESSFUL]');
      debugPrint(
          '✅ Successfully inserted new user into "${SupabaseConfig.userAuthTable}"!');
      debugPrint('✅ Full Name : ${newUser.fullName}');
      debugPrint('✅ Email     : ${newUser.email}');
      debugPrint('✅ Phone     : ${newUser.phone}');
      debugPrint('✅ Status    : ${newUser.status}');
      debugPrint('✅ Role      : ${newUser.role}');
      debugPrint('==================================================');

      return newUser;
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST205' ||
          pe.message.contains('schema cache') ||
          pe.message.contains('does not exist')) {
        debugPrint(
            '❌ [SUPABASE REGISTER] Table "${SupabaseConfig.userAuthTable}" not found in schema cache (PGRST205).');
        debugPrint(
            '👉 Please execute supabase_schema.sql in your Supabase SQL Editor.');
        throw const SupabaseAuthException(
          'Table "user_auth" does not exist in your Supabase database yet. Please run supabase_schema.sql in Supabase SQL Editor.',
        );
      }
      debugPrint(
          '❌ [SUPABASE INSERT ERROR] Code: ${pe.code}, Details: ${pe.message}');
      throw SupabaseAuthException(
          'Database registration failed: ${pe.message}');
    } on SupabaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [SUPABASE REGISTER ERROR] $e');
      throw SupabaseAuthException('Failed to register: ${e.toString()}');
    }
  }
}
