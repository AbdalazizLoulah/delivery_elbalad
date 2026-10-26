/// أدوات قراءة آمنة من JSON (Supabase / التخزين المحلي).
class JsonX {
  const JsonX._();

  static String str(Map<String, dynamic> json, String key, {String fallback = ''}) {
    final value = json[key];
    if (value == null) return fallback;
    return value.toString();
  }

  static String? strOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static double dbl(Map<String, dynamic> json, String key, {double fallback = 0}) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static double? dblOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int integer(Map<String, dynamic> json, String key, {int fallback = 0}) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? integerOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool boolean(Map<String, dynamic> json, String key, {bool fallback = false}) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  static DateTime date(Map<String, dynamic> json, String key, {DateTime? fallback}) {
    final value = json[key];
    if (value == null) return fallback ?? DateTime.now();
    return DateTime.tryParse(value.toString())?.toLocal() ?? fallback ?? DateTime.now();
  }

  static DateTime? dateOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static List<Map<String, dynamic>> list(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
