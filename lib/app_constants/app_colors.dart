import 'dart:ui';

class AppColors {
  const AppColors._();

  // ========================
  // BRAND
  // ========================
  static const primary = Color(0xFF224480); 
  static const primaryDark = Color(0xFF0B1F3A);

  // ========================
  // BACKGROUND
  // ========================
  static const scaffoldBg = Color(0xFFEBF3FF); // nền chính app
  static const surface = Color(0xFFFFFFFF); // card, container
  static const dark = Color.fromARGB(255, 0, 0, 0); // card, container
  static const surfaceLight = Color(0xFFF2F6FF); // nền phụ
  static const surfaceSecondary = Color(0xFFCFDEFF);

  // ========================
  // TEXT
  // ========================
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF0A2540);
  static const textMuted = Color(0xFF999999);

  // ========================
  // BORDER
  // ========================
  static const border = Color(0xFFD2D2D2);
  static const lightBorder =  Color.fromARGB(255, 244, 244, 244);

  // ========================
  // ICON
  // ========================
  static const iconPrimary = Color(0xFF333333);
  static const iconSecondary = Color(0xFF555555);
  static const iconDisabled = Color(0xFF999999);

  // ========================
  // STATUS / ACTION
  // ========================
  static const danger = Color(0xFFFF6B6B);
  static const dangerLight = Color(0xFFFFECEC);
  static const accent = Color(0xFFE64D32);
  static const star = Color(0xffFFD25D);
}
