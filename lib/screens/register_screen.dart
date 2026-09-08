import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/wavy_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool termsAccepted = false;
  int resendTimer = 45;
  bool isOtpSent = false;
  bool isResendEnabled = false;
  bool _isLoading = false;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    fullNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _handleRegistration() {
    // 1. Validation with AuthValidator
    final nameError = AuthValidator.validateFullName(fullNameController.text);
    if (nameError != null) {
      _showSnackBar(nameError);
      return;
    }

    final emailError = AuthValidator.validateEmail(emailController.text);
    if (emailError != null) {
      _showSnackBar(emailError);
      return;
    }

    final phoneError = AuthValidator.validatePhone(mobileController.text);
    if (phoneError != null) {
      _showSnackBar(phoneError);
      return;
    }

    final passError = AuthValidator.validatePassword(passwordController.text);
    if (passError != null) {
      _showSnackBar(passError);
      return;
    }

    final confirmError = AuthValidator.validateConfirmPassword(
      passwordController.text,
      confirmPasswordController.text,
    );
    if (confirmError != null) {
      _showSnackBar(confirmError);
      return;
    }

    if (!termsAccepted) {
      _showSnackBar('Please accept Terms & Conditions');
      return;
    }

    // 2. Generate and dispatch real-time in-app notification OTP (not SMS)
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final generatedOtp = auth.sendRealTimeRegistrationOtp(
      phone: AuthValidator.cleanPhone(mobileController.text),
      name: fullNameController.text.trim(),
    );

    setState(() {
      isOtpSent = true;
      resendTimer = 45;
      isResendEnabled = false;
    });
    _startResendTimer();

    _showSnackBar('🔔 [Notification] Your GaGa verification OTP is $generatedOtp');
  }

  void _handleVerifyAndRegister() async {
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('Please enter valid 6-digit OTP');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Verify against real-time generated OTP
    if (!auth.verifyRegistrationOtp(otp)) {
      _showSnackBar('Invalid OTP! Please check the code in the notification banner.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = await auth.register(
      fullNameController.text.trim(),
      emailController.text.trim(),
      AuthValidator.cleanPhone(mobileController.text),
      passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showSnackBar('Registration successful! Welcome to GaGa Housie.');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar(auth.errorMessage ?? 'Registration failed. Please try again.');
    }
  }

  void _resendOTP() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final newOtp = auth.sendRealTimeRegistrationOtp(
      phone: AuthValidator.cleanPhone(mobileController.text),
      name: fullNameController.text.trim(),
    );

    setState(() {
      resendTimer = 45;
      isResendEnabled = false;
    });
    _startResendTimer();
    _showSnackBar('🔔 [Notification] New verification OTP is $newOtp');
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
              subtitle: 'Create Account • Join the Platform',
            ),

            // Form inputs & actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Full Name Field
                  _buildGlassInputField(
                    controller: fullNameController,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  // Email Address Field
                  _buildGlassInputField(
                    controller: emailController,
                    hint: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number Field (Strictly 10 digits)
                  _buildGlassInputField(
                    controller: mobileController,
                    hint: '10-Digit Mobile Number',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Choose Password Field
                  _buildGlassInputField(
                    controller: passwordController,
                    hint: 'Choose Password (min 4 chars)',
                    obscureText: !isPasswordVisible,
                    icon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.primaryGreen.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  _buildGlassInputField(
                    controller: confirmPasswordController,
                    hint: 'Confirm Password',
                    obscureText: !isConfirmPasswordVisible,
                    icon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.primaryGreen.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Terms & Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            termsAccepted = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryGreen,
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(0.5),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms & Conditions',
                          style: TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Register Button
                  if (!isOtpSent)
                    _buildGradientButton(
                      text: 'Register',
                      isLoading: _isLoading,
                      onPressed: _handleRegistration,
                    ),

                  if (isOtpSent) ...[
                    const SizedBox(height: 16),

                    // Real-time Notification Banner for OTP
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final currentOtp = auth.activeRegistrationOtp ?? '------';
                        return _buildRealTimeNotificationCard(currentOtp);
                      },
                    ),

                    // OTP Input Field
                    _buildGlassInputField(
                      controller: otpController,
                      hint: 'Enter 6-digit OTP',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      icon: Icons.security_outlined,
                    ),

                    const SizedBox(height: 12),

                    // Resend OTP Timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resend OTP in ${resendTimer}s',
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
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Continue Button
                    _buildGradientButton(
                      text: 'Verify & Complete Registration',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? () {} : _handleVerifyAndRegister,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Login Link
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  /// Real-Time in-app notification banner for verification code
  Widget _buildRealTimeNotificationCard(String otp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primaryGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'REAL-TIME IN-APP NOTIFICATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE OTP',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your verification code for GaGa Housie is:',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                otp,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGreen,
                  letterSpacing: 6,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  otpController.text = otp;
                  _showSnackBar('OTP $otp auto-filled!');
                },
                icon: const Icon(Icons.touch_app_rounded, size: 15, color: AppColors.primaryGreen),
                label: const Text(
                  'Auto-Fill',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 14,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          counterText: '',
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: AppColors.primaryGreen,
                  size: 22,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.greenGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glowGreen,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
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
