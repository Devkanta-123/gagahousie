import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/wavy_header.dart';

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
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _handleOTPVerification() async {
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
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && resendTimer > 0) {
        setState(() {
          resendTimer--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            isResendEnabled = true;
          });
        }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Professional Wavy Header with back button, GaGa branding, and subtitle
            WavyBrandedHeader(
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
              subtitle: 'Verification • Enter OTP',
              icon: Icons.sms_rounded,
            ),

            // OTP Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  const Text(
                    'OTP Verification',
                    style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Enter the 6-digit verification code sent to your\nregistered mobile number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 6-digit OTP Input Box
                  _buildOTPInputField(),

                  const SizedBox(height: 20),

                  // Resend OTP Row
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive OTP? ",
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          if (isResendEnabled)
                            TextButton(
                              onPressed: _resendOTP,
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Resend in ${resendTimer}s',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Verify Button
                  _buildGradientButton(
                    text: 'Verify & Continue',
                    onPressed: _handleOTPVerification,
                  ),

                  const SizedBox(height: 24),

                  // Back to Login link
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPInputField() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: '••••••',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.4),
                  fontSize: 22,
                  letterSpacing: 10,
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
              _isOtpVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.primaryGreen.withOpacity(0.75),
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
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.greenGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowGreen,
            blurRadius: 12,
            offset: const Offset(0, 3),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
