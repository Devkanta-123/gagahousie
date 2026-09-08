import 'package:flutter/material.dart';

class AppColors {
  // Brand Green Color Palette
  static const Color primary =
      Color(0xFF196144); // Deep teal green - Primary brand color
  static const Color primaryGreen = Color(0xFF196144); // Deep teal green
  static const Color secondaryGreen = Color(0xFF0F4A33); // Darker teal green
  static const Color accentGreen =
      Color(0xFF00B894); // Fresh mint emerald accent
  static const Color glowGreen = Color(0x20196144); // Soft teal glow

  // Professional White & Surface Colors
  static const Color background =
      Color(0xFFF7FBF9); // Clean professional white with subtle mint tint
  static const Color pureWhite = Color(0xFFFFFFFF); // Pure white
  static const Color cardWhite =
      Color(0xFFFFFFFF); // Clean white card background
  static const Color surface = Color(0xFFFFFFFF); // Surface white
  static const Color glass = Color(0xFFFFFFFF); // Glass / card surface
  static const Color glassBorder =
      Color(0x26196144); // Subtle teal border (15% opacity)

  // Typography & Text
  static const Color white =
      Color(0xFF196144); // Preserved for legacy label usages across screens
  static const Color hint = Color(0xFF8A9E96); // Muted teal-gray
  static const Color black =
      Color(0xFF1F2937); // Charcoal black for crisp readability
  static const Color textPrimary =
      Color(0xFF196144); // Primary green text color
  static const Color textSecondary =
      Color(0xFF5A7A6E); // Light teal-gray for secondary text
  static const Color textDark = Color(0xFF1F2937); // Dark text

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0F4A33), // Darker teal
      Color(0xFF196144), // Primary teal
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF196144), // Primary teal
      Color(0xFF0F4A33), // Darker teal
    ],
  );
}

class AppStrings {
  static const String appName = 'GaGa';
  static const String appSubtitle = 'Housie Tambola';
  static const String welcomeBack = 'Welcome Back';
  static const String loginSecurely = 'Log In Securely';
  static const String joinPlatform = 'Join the Platform';
  static const String nexusPay = 'NEXUSPAY';
  static const String orVerifyWithOTP = 'OR VERIFY WITH OTP';
  static const String orRegisterWith = 'OR REGISTER WITH';
  static const String balance = 'BALANCE';
  static const String upcomingTickets = 'Upcoming Tickets';
  static const String viewAll = 'View All';
  static const String drawDate = 'Draw Date:';
  static const String drawTime = 'Draw Time:';
  static const String drawWinners = 'Draw Winners';
}

class AppDimens {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 40.0;

  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;

  static const double textSmall = 12.0;
  static const double textMedium = 14.0;
  static const double textLarge = 16.0;
  static const double textXLarge = 18.0;
  static const double textXXLarge = 20.0;
  static const double textXXXLarge = 28.0;
  static const double textDisplay = 42.0;
}
