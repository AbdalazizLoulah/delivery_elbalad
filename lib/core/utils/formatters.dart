import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../localization/app_localization.dart';

class Formatters {
  const Formatters._();

  static String get _localeCode => AppLocale.isEnglish ? 'en' : 'ar';

  static NumberFormat get _money => NumberFormat('#,##0.##', _localeCode);

  static String money(num value) => AppLocale.isEnglish
      ? '${_money.format(value)} EGP'
      : '${_money.format(value)} ${AppConfig.currency}';

  static String dateTime(DateTime value) =>
      DateFormat('d MMM y - h:mm a', _localeCode).format(value.toLocal());

  static String date(DateTime value) =>
      DateFormat('d MMM y', _localeCode).format(value.toLocal());

  static String timeAgo(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (AppLocale.isEnglish) {
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 30) return '${diff.inDays} days ago';
      return date(value);
    }
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'من ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'من ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'من ${diff.inDays} يوم';
    return date(value);
  }

  static String distanceKm(double km) {
    if (AppLocale.isEnglish) {
      if (km < 1) return '${(km * 1000).round()} m';
      return '${km.toStringAsFixed(1)} km';
    }
    if (km < 1) return '${(km * 1000).round()} متر';
    return '${km.toStringAsFixed(1)} كم';
  }

  /// زمن الوصول المتوقع بالدقائق بشكل مقروء.
  static String durationMinutes(double minutes) {
    final total = minutes.round();
    if (AppLocale.isEnglish) {
      if (total <= 1) return 'Less than a minute';
      if (total < 60) return '$total min';
      final hours = total ~/ 60;
      final rest = total % 60;
      if (rest == 0) return '$hours h';
      return '$hours h $rest min';
    }
    if (total <= 1) return 'أقل من دقيقة';
    if (total < 60) return '$total دقيقة';
    final hours = total ~/ 60;
    final rest = total % 60;
    if (rest == 0) return '$hours ساعة';
    return '$hours ساعة و$rest دقيقة';
  }

  static String orderCode(DateTime createdAt, String id) {
    final suffix = id.replaceAll('-', '').substring(0, 4).toUpperCase();
    return '#${DateFormat('yyMMdd').format(createdAt)}-$suffix';
  }
}
