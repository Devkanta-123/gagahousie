import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_config.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/wavy_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Test Supabase connection on screen load and print status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectionStatus();
    });
  }

  void _checkConnectionStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('--------------------------------------------------');
    debugPrint(
        '🔍 [LOGIN SCREEN] Checking Supabase connection for login system...');
    final result = await auth.checkSupabaseConnection();
    if (result.success) {
      debugPrint(
          '✅ [LOGIN SCREEN] Supabase connection is active & ready for authentication!');
    } else {
      debugPrint('ℹ️ [LOGIN SCREEN] Supabase status: ${result.message}');
    }
    debugPrint('--------------------------------------------------');
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    // 1. Validation with AuthValidator
    final identifierError = AuthValidator.validateLoginIdentifier(identifier);
    if (identifierError != null) {
      _showSnackBar(identifierError);
      return;
    }

    final passwordError = AuthValidator.validatePassword(password);
    if (passwordError != null) {
      _showSnackBar(passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('==================================================');
    debugPrint('🚀 [LOGIN SYSTEM] Initiating Supabase Authentication...');
    debugPrint('🔑 [LOGIN SYSTEM] Identifier: $identifier');
    debugPrint('🔑 [LOGIN SYSTEM] Table: ${SupabaseConfig.userAuthTable}');

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.login(identifier, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      debugPrint(
          '🎉 [LOGIN SYSTEM] Login SUCCESSFUL for $identifier! Redirecting to Home...');
      debugPrint('==================================================');
      _showSnackBar('Login successful! Welcome back.');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final errorMsg = auth.errorMessage ??
          'Invalid credentials. Please verify your email/phone and password.';
      debugPrint('❌ [LOGIN SYSTEM] Login failed: $errorMsg');
      debugPrint('==================================================');
      _showSnackBar(errorMsg);
    }
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
            // Professional Wavy Header with GaGa branding and welcome
            const WavyBrandedHeader(
              subtitle: 'Welcome Back • Sign In to Continue',
            ),

            // Form inputs & actions
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supabase Connection Status Bar
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isConnected = auth.isSupabaseConnected;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConnected
                                ? const Color(0xFF4CAF50).withOpacity(0.3)
                                : const Color(0xFFFFC107).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isConnected
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_queue_rounded,
                              size: 18,
                              color: isConnected
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFF57F17),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isConnected
                                    ? 'Supabase: Connected (user_auth ready)'
                                    : 'Supabase: Connecting to DB...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isConnected
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _checkConnectionStatus,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: Text(
                                  'Test',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isConnected
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFFBF360C),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Email or 10-Digit Mobile Field
                  _buildGlassInputField(
                    controller: identifierController,
                    hint: 'Email Address or 10-Digit Mobile',
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  // Password Field with Eye Toggle
                  _buildGlassInputField(
                    controller: passwordController,
                    hint: 'Password',
                    obscureText: _obscurePassword,
                    icon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.primaryGreen.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showSnackBar('Contact admin to reset password.');
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Sign In Button with Green Gradient
                  _buildGradientButton(
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? () {} : _handleLogin,
                  ),

                  const SizedBox(height: 28),

                  // Register Link
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              'Sign Up',
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
          border: InputBorder.none,
          counterText: '',
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: AppColors.primaryGreen,
                  size: 22,
                )
              : null,
          suffixIcon: suffixIcon,
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
