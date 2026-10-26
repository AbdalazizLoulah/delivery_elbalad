import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_localization.dart';

/// بديل `Text` بيترجم النص حسب لغة التطبيق وبيتكيّف مع الوضع الغامق.
///
/// بنستخدمه في كل الواجهة بدل `Text`، فمش محتاجين نغيّر كل النصوص العربية
/// يدويًا ولا نضيف شروط في كل مكان.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    // بنسجّل الاعتماد على Localizations علشان العنصر يتحدّث فورًا لما المستخدم
    // يغيّر اللغة، بس بنترجم بالحالة العامة (AppLocale) لأنها مصدر الحقيقة.
    Localizations.maybeLocaleOf(context);
    final currentLocale = locale ?? AppLocale.current;
    return Text(
      tr(text, locale: currentLocale),
      style: _adaptStyle(Theme.of(context), style),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  static TextStyle? _adaptStyle(ThemeData theme, TextStyle? style) {
    if (style == null || theme.brightness != Brightness.dark) return style;
    final scheme = theme.colorScheme;
    final color = style.color;

    if (color == AppColors.textPrimary) {
      return style.copyWith(color: scheme.onSurface);
    }
    if (color == AppColors.textSecondary) {
      return style.copyWith(color: scheme.onSurfaceVariant);
    }
    if (color == AppColors.textHint) {
      return style.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.78));
    }
    if (color == AppColors.primaryDark || color == AppColors.primary) {
      return style.copyWith(color: scheme.primary);
    }
    if (color == AppColors.border) {
      return style.copyWith(color: scheme.outlineVariant);
    }
    return style;
  }
}
