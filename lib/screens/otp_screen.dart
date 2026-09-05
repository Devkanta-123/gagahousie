import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  int resendTimer = 45;
  bool isResendEnabled = false;
  bool _isOtpVisible = false;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF5F0E8),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F0E8),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo/Icon with Green Gradient
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00B894),
                            Color(0xFF00A381),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B894).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sms,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Title
                    const Text(
                      'OTP Verification',
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    Text(
                      'Enter the 6-digit OTP sent to your',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 5),
                    
                    Text(
                      'registered mobile number',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // OTP Input Field with Visibility Toggle
                    _buildOTPInputField(),
                    
                    const SizedBox(height: 20),
                    
                    // Resend OTP Timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn\'t receive OTP? ',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        if (isResendEnabled)
                          TextButton(
                            onPressed: _resendOTP,
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Color(0xFF00B894),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Resend in ${resendTimer}s',
                            style: TextStyle(
                              color: const Color(0xFF00B894).withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Verify Button
                    _buildGradientButton(
                      text: 'Verify & Continue',
                      onPressed: _handleOTPVerification,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Back to Login
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: const Color(0xFF00B894).withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildOTPInputField() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: !_isOtpVisible,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '------',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.5),
                  fontSize: 20,
                  letterSpacing: 8,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isOtpVisible = !_isOtpVisible;
              });
            },
            icon: Icon(
              _isOtpVisible ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF00B894),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00B894),
            Color(0xFF00A381),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
  
  void _handleOTPVerification() async {
    // Get the actual OTP value (visible or hidden doesn't affect the value)
    String otp = otpController.text.trim();
    
    if (otp.length != 6) {
      _showSnackBar('Please enter valid 6-digit OTP');
      return;
    }
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.verifyOTP(otp);
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Invalid OTP. Please try again.');
    }
  }
  
  void _resendOTP() {
    setState(() {
      resendTimer = 45;
      isResendEnabled = false;
    });
    _startResendTimer();
    _showSnackBar('OTP resent successfully');
  }
  
  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && resendTimer > 0) {
        setState(() {
          resendTimer--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          isResendEnabled = true;
        });
      }
    });
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2C3E50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}