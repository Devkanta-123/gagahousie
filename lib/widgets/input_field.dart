import 'package:flutter/material.dart';
import '../utils/constants.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon; // Made icon optional
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLength;

  const InputField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass, // Changed to glass effect
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
        border: Border.all(
          color: AppColors.glassBorder, // Added green glass border
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: AppColors.hint), // Updated to use hint color
          prefixIcon: icon != null
              ? Icon(icon,
                  color: AppColors.primaryGreen) // Changed to green color
              : null,
          suffixIcon: suffixIcon,
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingMedium,
          ),
        ),
      ),
    );
  }
}
