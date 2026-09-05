import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF196144);  // Deep teal green - Primary brand color
  static const Color background = Color(0xFFF5F0E8); // Very light mint-gray background
  static const Color primaryGreen = Color.fromARGB(255, 25, 97, 85);  // Deep teal green
  static const Color secondaryGreen = Color(0xFF0F4A33);  // Darker teal green
  static const Color glowGreen = Color(0x30196144);  // Soft teal glow
  static const Color glass = Color(0x1AFFFFFF);  // Glass effect
  static const Color glassBorder = Color(0x33196144);  // Teal border
  static const Color white =  Color(0xFF196144);
  static const Color hint = Color(0xFFF5F0E8);  // Muted teal-gray
  static const Color black = Color(0xFF000000);  // Pure black
  static const Color textPrimary = Color(0xFF196144); // White text color
  static const Color textSecondary =  Color(0xFF196144);  // Light white-gray for secondary text
  
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0F4A33),  // Darker teal
      Color(0xFF196144),  // Primary teal
    ],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF196144),  // Primary teal
      Color(0xFF0F4A33),  // Darker teal
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