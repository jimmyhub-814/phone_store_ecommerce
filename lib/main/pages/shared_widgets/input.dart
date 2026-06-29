// --- Custom Widget ---
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';

class InputFormS extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final TextInputType? keyboard;
  final VoidCallback? onTap;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  const InputFormS({
    super.key,
    required this.controller,
    required this.hintText,
    this.readOnly = false,
    this.keyboard = TextInputType.text,
    this.onTap,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: keyboard,
      validator: validator,
      onTap: onTap,
      controller: controller,
      style: AppTextstyles.headingH6.copyWith(color: AppColors.surface),
      obscureText: obscureText,
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: AppTextstyles.headingH6.copyWith(
          color: Colors.white.withValues(alpha: 0.8),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

InputDecoration inputDecoration(String label, {Icon? icon, Widget? suffix}) {
  return InputDecoration(
    prefixIcon: icon,
    suffixIcon: suffix,
    hintText: label,
    hintStyle: const TextStyle(fontWeight: FontWeight.w500),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
