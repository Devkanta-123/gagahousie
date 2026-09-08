import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  String? _username;
  String? _userEmail;
  String? _errorMessage;
  UserModel? _currentUser;
  String? _activeRegistrationOtp;

  bool get isLoggedIn => _isLoggedIn;
  bool get isOtpVerified => _isOtpVerified;
  bool get isLoading => _isLoading;
  String? get username => _username;
  String? get fullName => _currentUser?.fullName ?? _username;
  String? get userEmail => _userEmail;
  String? get userPhone => _currentUser?.phone;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get userRole => _currentUser?.role;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get activeRegistrationOtp => _activeRegistrationOtp;

  bool get isSupabaseConnected => SupabaseService.instance.isConnected;
  String get connectionStatusMessage => SupabaseService.instance.lastConnectionMessage;

  /// Authenticate strictly against Supabase user_auth table
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await SupabaseService.instance.authenticate(
        identifier: identifier,
        password: password,
      );

      _currentUser = user;
      _isLoggedIn = true;
      _username = user.fullName.isNotEmpty ? user.fullName : user.email.split('@')[0];
      _userEmail = user.email;
      _isOtpVerified = true; // Logged in directly from DB
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Dispatch real-time in-app notification OTP for registration
  String sendRealTimeRegistrationOtp({required String phone, required String name}) {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    _activeRegistrationOtp = otp;

    debugPrint('==================================================');
    debugPrint('🔔 [REAL-TIME NOTIFICATION DISPATCHED]');
    debugPrint('👤 Recipient    : $name');
    debugPrint('📱 Phone Number : $phone');
    debugPrint('🔑 Generated OTP: $otp');
    debugPrint('📡 Delivery     : In-App Real-Time Notification');
    debugPrint('==================================================');

    notifyListeners();
    return otp;
  }

  /// Verifies entered OTP against the real-time generated OTP
  bool verifyRegistrationOtp(String code) {
    if (_activeRegistrationOtp == null) return false;
    final valid = _activeRegistrationOtp == code.trim();
    if (valid) {
      _isOtpVerified = true;
      notifyListeners();
    }
    return valid;
  }

  /// Register user into Supabase user_auth table
  Future<bool> register(
    String fullName,
    String email,
    String mobile,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await SupabaseService.instance.register(
        fullName: fullName,
        email: email,
        phone: mobile,
        password: password,
      );

      _currentUser = newUser;
      _isLoggedIn = true;
      _username = newUser.fullName;
      _userEmail = newUser.email;
      _isOtpVerified = true;
      _isLoading = false;
      _activeRegistrationOtp = null;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Check / test Supabase connection and notify UI
  Future<SupabaseConnectionResult> checkSupabaseConnection() async {
    final result = await SupabaseService.instance.testConnection();
    notifyListeners();
    return result;
  }

  Future<bool> verifyOTP(String otp) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Verify against generated OTP if active, or valid 6-digit numeric
    if (_activeRegistrationOtp != null) {
      return verifyRegistrationOtp(otp);
    }
    if (otp.length == 6 && RegExp(r'^\d+$').hasMatch(otp)) {
      _isOtpVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _isOtpVerified = false;
    _username = null;
    _userEmail = null;
    _currentUser = null;
    _errorMessage = null;
    _activeRegistrationOtp = null;
    notifyListeners();
  }
}