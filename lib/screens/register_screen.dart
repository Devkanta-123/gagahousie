import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Back Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2C3E50),
                      ),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Join the Platform',
                            style: TextStyle(
                              color: Color(0xFF5D6D7E),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
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
                    
                    // Mobile Number Field
                    _buildGlassInputField(
                      controller: mobileController,
                      hint: 'Mobile Number',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    
                    // Choose Password Field
                    _buildGlassInputField(
                      controller: passwordController,
                      hint: 'Choose Password',
                      obscureText: !isPasswordVisible,
                      icon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF00B894),
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
                          isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF00B894),
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
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
                          activeColor: const Color(0xFF00B894),
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: const Color(0xFF00B894).withOpacity(0.5),
                          ),
                        ),
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: const Color(0xFF2C3E50),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Register Button
                    _buildGradientButton(
                      text: 'Register',
                      onPressed: _handleRegistration,
                    ),
                    
                    if (isOtpSent) ...[
                      const SizedBox(height: 24),
                      
                      // OTP Section
                      _buildGlassInputField(
                        controller: otpController,
                        hint: 'Enter OTP',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        icon: Icons.security_outlined,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Resend OTP Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Resend OTP in ${resendTimer}:45',
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          if (isResendEnabled)
                            TextButton(
                              onPressed: _resendOTP,
                              child: Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: const Color(0xFF00B894),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Continue Button
                      _buildGradientButton(
                        text: 'Continue',
                        onPressed: _handleVerifyAndRegister,
                      ),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFF00B894),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.withOpacity(0.6),
            fontSize: 15,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          counterText: '',
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: const Color(0xFF00B894).withOpacity(0.6),
                  size: 22,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
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
  
  void _handleRegistration() async {
    if (fullNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        mobileController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }
    
    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }
    
    if (!termsAccepted) {
      _showSnackBar('Please accept Terms & Conditions');
      return;
    }
    
    setState(() {
      isOtpSent = true;
      resendTimer = 45;
      isResendEnabled = false;
    });
    _startResendTimer();
    
    _showSnackBar('OTP sent to your mobile number');
  }
  
  void _handleVerifyAndRegister() async {
    if (otpController.text.length == 6) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      bool success = await auth.register(
        fullNameController.text,
        emailController.text,
        mobileController.text,
        passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      _showSnackBar('Please enter valid 6-digit OTP');
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
    fullNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }
}