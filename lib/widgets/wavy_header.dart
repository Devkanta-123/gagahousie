import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'wavy_header_clipper.dart';

export 'wavy_header_clipper.dart';

/// Professional wavy branded header used for authentication flows (Login, Register, OTP).
class WavyBrandedHeader extends StatelessWidget {
  final String title;
  final String badgeText;
  final String? subtitle;
  final String? demoCredential;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final IconData icon;

  const WavyBrandedHeader({
    super.key,
    this.title = 'GaGa',
    this.badgeText = 'HOUSIE TAMBOLA',
    this.subtitle,
    this.demoCredential,
    this.showBackButton = false,
    this.onBackPressed,
    this.icon = Icons.confirmation_number_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Subtle soft shadow behind the wave
        ClipPath(
          clipper: WavyHeaderClipper(),
          child: Container(
            height: 310,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0C3827).withOpacity(0.25),
                  AppColors.primaryGreen.withOpacity(0.2),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Main Wavy Gradient Header
        ClipPath(
          clipper: WavyHeaderClipper(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF092E20),
                  Color(0xFF13523A),
                  Color(0xFF196144),
                  Color(0xFF00B894),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row with optional back button
                    if (showBackButton)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: onBackPressed ??
                              () => Navigator.maybePop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 6),

                    // Brand Icon Emblem (White circle with green icon)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: AppColors.primaryGreen,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // GaGa Brand Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Housie Tambola Subtitle Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),

                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],

                    if (demoCredential != null &&
                        demoCredential!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          demoCredential!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
