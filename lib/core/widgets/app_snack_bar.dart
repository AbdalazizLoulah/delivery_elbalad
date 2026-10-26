import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import '../localization/app_text.dart';
import '../theme/app_colors.dart';

/// رسائل موحدة للتطبيق.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  final color = isError
      ? AppColors.danger
      : isSuccess
          ? AppColors.success
          : AppColors.textPrimary;
  final translated = tr(message, locale: Localizations.localeOf(context));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: AppText(translated, style: const TextStyle(color: Colors.white)),
      ),
    );
}
