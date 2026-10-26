import 'package:flutter/material.dart';

/// أدوات بسيطة عشان الواجهة تتظبط على أي مقاس (طولي/عرضي/أجهزة كبيرة).
class Responsive {
  const Responsive._();

  /// أقصى عرض للمحتوى — بيمنع المحتوى يتمدد أوي على الأجهزة الكبيرة.
  static const double maxContentWidth = 760;

  /// أقصى عرض لصفحات المنتجات (أوسع شوية عشان الشبكة تبان حلوة).
  static const double maxGridWidth = 1000;

  /// عدد أعمدة الشبكة حسب عرض الشاشة.
  static int gridColumns(double width) {
    if (width >= 1000) return 4;
    if (width >= 620) return 3;
    return 2;
  }

  /// نسبة العرض للارتفاع لعناصر الشبكة (بتقل مع زيادة الأعمدة).
  static double gridAspectRatio(double width, int columns) {
    if (columns >= 4) return 0.7;
    if (columns == 3) return 0.66;
    if (width < 360) return 0.58;
    return 0.66;
  }

  /// حواف أفقية مناسبة لحجم الشاشة.
  static double horizontalPadding(double width) {
    if (width >= 1000) return 24;
    if (width >= 600) return 18;
    return 14;
  }

  /// هل الشاشة عرضية (أعرض من طولها)؟
  static bool isLandscape(BoxConstraints constraints) =>
      constraints.maxWidth > constraints.maxHeight;

  /// هل الشاشة قصيرة (أقل من 500 بكسل ارتفاع)؟
  static bool isShortScreen(BoxConstraints constraints) =>
      constraints.maxHeight > 0 && constraints.maxHeight < 500;

  /// بيحط المحتوى في عرض أقصى وبيوسّطه.
  static Widget centerContent(
    Widget child, {
    double maxWidth = maxContentWidth,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
