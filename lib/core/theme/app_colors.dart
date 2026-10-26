import 'package:flutter/material.dart';

/// ألوان الهوية البصرية لتطبيق "ديليفاري البلد".
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF0F6E5C);
  static const Color primaryDark = Color(0xFF0A4F42);
  static const Color primaryLight = Color(0xFFE3F2EE);
  static const Color accent = Color(0xFFF5A524);
  static const Color accentLight = Color(0xFFFFF4E0);

  static const Color success = Color(0xFF2E9E5B);
  static const Color danger = Color(0xFFE14B4B);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFEB9B24);

  static const Color background = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE6E8EC);
  static const Color textPrimary = Color(0xFF1B1D21);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  /// نسخة أفتح من اللون — بتستخدم في الوضع الغامق عشان الألوان تبقى واضحة.
  static Color lighten(Color color, [double amount = 0.34]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
