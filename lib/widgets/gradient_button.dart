import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFullWidth;
  final double? height;
  
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 52,
      decoration: BoxDecoration(
        gradient: AppColors.greenGradient,  // Updated to use green gradient
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowGreen,  // Added green glow effect
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.background,  // Changed to background color for contrast
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: AppDimens.textLarge,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}