import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isOtpVerified = false;
  String? _username;
  String? _userEmail;
  
  bool get isLoggedIn => _isLoggedIn;
  bool get isOtpVerified => _isOtpVerified;
  String? get username => _username;
  String? get userEmail => _userEmail;
  
  // Default credentials
  final String defaultEmail = 'admin@gmail.com';
  final String defaultPassword = '1234';
  
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (email == defaultEmail && password == defaultPassword) {
      _isLoggedIn = true;
      _username = email.split('@')[0];
      _userEmail = email;
      _isOtpVerified = false; // Reset OTP status on login
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<bool> verifyOTP(String otp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Any 6-digit OTP works for demo
    if (otp.length == 6 && RegExp(r'^\d+$').hasMatch(otp)) {
      _isOtpVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<bool> register(String fullName, String email, String mobile, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // For demo purposes, registration always succeeds
    return true;
  }
  
  void logout() {
    _isLoggedIn = false;
    _isOtpVerified = false;
    _username = null;
    _userEmail = null;
    notifyListeners();
  }
}