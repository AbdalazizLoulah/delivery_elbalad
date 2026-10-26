import 'package:flutter/services.dart';

/// حدود جغرافية تقريبية للبلد (بتستخدم لمقارنة عنوان المتجر وعنوان العميل
/// والطيار من غير ما نحتاج خدمة خارجية).
class CountryBounds {
  const CountryBounds(this.minLat, this.maxLat, this.minLng, this.maxLng);

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
}

/// بيانات بلد: كود الاتصال وعدد أرقام الموبايل المسموح بيها.
class CountryInfo {
  const CountryInfo({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.dialCode,
    required this.nationalLength,
    this.localLength,
    this.alternateNationalLengths = const [],
    this.bounds,
  });

  /// كود ISO ثنائي الحروف (EG / SA / AE ...).
  final String code;
  final String nameAr;
  final String nameEn;

  /// كود الاتصال الدولي بدون + (مثال: 20 لمصر).
  final String dialCode;

  /// عدد الأرقام الوطنية بدون صفر البداية (مثال: 10 لمصر).
  final int nationalLength;

  /// عدد الأرقام في الصيغة المحلية بالصفر (مثال: 11 لمصر).
  final int? localLength;

  /// أطوال وطنية بديلة (بعض الدول عندها أكثر من طول).
  final List<int> alternateNationalLengths;

  final CountryBounds? bounds;

  bool acceptsNationalLength(int length) =>
      length == nationalLength || alternateNationalLengths.contains(length);

  int get maxNationalLength => alternateNationalLengths.fold<int>(
        nationalLength,
        (value, length) => length > value ? length : value,
      );

  /// أقصى عدد أرقام ممكن في الحقل (كود الدولة + الرقم الوطني، أو الصيغة المحلية).
  int get maxPhoneDigits {
    final withDial = dialCode.length + maxNationalLength;
    final local = localLength ?? nationalLength;
    return withDial > local ? withDial : local;
  }

  String label(String languageCode) =>
      '+$dialCode ${languageCode == 'ar' ? nameAr : nameEn}';

  @override
  bool operator ==(Object other) =>
      other is CountryInfo && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// قائمة الدول المدعومة في التطبيق + أدوات استنتاج البلد من رقم الموبايل
/// أو من الإحداثيات.
class Countries {
  const Countries._();

  static const CountryInfo egypt = CountryInfo(
    code: 'EG',
    nameAr: 'مصر',
    nameEn: 'Egypt',
    dialCode: '20',
    nationalLength: 10,
    localLength: 11,
    bounds: CountryBounds(22.0, 31.7, 24.7, 36.9),
  );

  static const CountryInfo saudiArabia = CountryInfo(
    code: 'SA',
    nameAr: 'السعودية',
    nameEn: 'Saudi Arabia',
    dialCode: '966',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(16.0, 32.2, 34.4, 55.7),
  );

  static const CountryInfo uae = CountryInfo(
    code: 'AE',
    nameAr: 'الإمارات',
    nameEn: 'United Arab Emirates',
    dialCode: '971',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(22.6, 26.1, 51.5, 56.4),
  );

  static const CountryInfo kuwait = CountryInfo(
    code: 'KW',
    nameAr: 'الكويت',
    nameEn: 'Kuwait',
    dialCode: '965',
    nationalLength: 8,
    bounds: CountryBounds(28.5, 30.1, 46.5, 48.5),
  );

  static const CountryInfo qatar = CountryInfo(
    code: 'QA',
    nameAr: 'قطر',
    nameEn: 'Qatar',
    dialCode: '974',
    nationalLength: 8,
    bounds: CountryBounds(24.4, 26.2, 50.7, 51.7),
  );

  static const CountryInfo bahrain = CountryInfo(
    code: 'BH',
    nameAr: 'البحرين',
    nameEn: 'Bahrain',
    dialCode: '973',
    nationalLength: 8,
    bounds: CountryBounds(25.7, 26.3, 50.3, 50.7),
  );

  static const CountryInfo oman = CountryInfo(
    code: 'OM',
    nameAr: 'عمان',
    nameEn: 'Oman',
    dialCode: '968',
    nationalLength: 8,
    bounds: CountryBounds(16.6, 26.4, 52.0, 59.9),
  );

  static const CountryInfo jordan = CountryInfo(
    code: 'JO',
    nameAr: 'الأردن',
    nameEn: 'Jordan',
    dialCode: '962',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(29.1, 33.4, 34.9, 39.3),
  );

  static const CountryInfo palestine = CountryInfo(
    code: 'PS',
    nameAr: 'فلسطين',
    nameEn: 'Palestine',
    dialCode: '970',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(31.2, 32.6, 34.2, 35.6),
  );

  static const CountryInfo iraq = CountryInfo(
    code: 'IQ',
    nameAr: 'العراق',
    nameEn: 'Iraq',
    dialCode: '964',
    nationalLength: 10,
    localLength: 11,
    bounds: CountryBounds(29.0, 37.4, 38.7, 48.6),
  );

  static const CountryInfo libya = CountryInfo(
    code: 'LY',
    nameAr: 'ليبيا',
    nameEn: 'Libya',
    dialCode: '218',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(19.5, 33.2, 9.3, 25.2),
  );

  static const CountryInfo sudan = CountryInfo(
    code: 'SD',
    nameAr: 'السودان',
    nameEn: 'Sudan',
    dialCode: '249',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(8.6, 22.2, 21.8, 38.6),
  );

  static const CountryInfo morocco = CountryInfo(
    code: 'MA',
    nameAr: 'المغرب',
    nameEn: 'Morocco',
    dialCode: '212',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(27.6, 35.9, -13.2, -1.0),
  );

  static const CountryInfo algeria = CountryInfo(
    code: 'DZ',
    nameAr: 'الجزائر',
    nameEn: 'Algeria',
    dialCode: '213',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(18.9, 37.1, -8.7, 12.0),
  );

  static const CountryInfo tunisia = CountryInfo(
    code: 'TN',
    nameAr: 'تونس',
    nameEn: 'Tunisia',
    dialCode: '216',
    nationalLength: 8,
    bounds: CountryBounds(30.2, 37.5, 7.5, 11.6),
  );

  static const CountryInfo turkey = CountryInfo(
    code: 'TR',
    nameAr: 'تركيا',
    nameEn: 'Turkey',
    dialCode: '90',
    nationalLength: 10,
    localLength: 11,
    bounds: CountryBounds(35.8, 42.1, 25.6, 44.8),
  );

  static const CountryInfo unitedKingdom = CountryInfo(
    code: 'GB',
    nameAr: 'المملكة المتحدة',
    nameEn: 'United Kingdom',
    dialCode: '44',
    nationalLength: 10,
    localLength: 11,
    bounds: CountryBounds(49.9, 60.9, -8.6, 1.8),
  );

  static const CountryInfo germany = CountryInfo(
    code: 'DE',
    nameAr: 'ألمانيا',
    nameEn: 'Germany',
    dialCode: '49',
    nationalLength: 10,
    alternateNationalLengths: [11],
    localLength: 12,
    bounds: CountryBounds(47.2, 55.1, 5.8, 15.1),
  );

  static const CountryInfo france = CountryInfo(
    code: 'FR',
    nameAr: 'فرنسا',
    nameEn: 'France',
    dialCode: '33',
    nationalLength: 9,
    localLength: 10,
    bounds: CountryBounds(41.3, 51.1, -5.2, 9.6),
  );

  static const CountryInfo usa = CountryInfo(
    code: 'US',
    nameAr: 'الولايات المتحدة',
    nameEn: 'United States',
    dialCode: '1',
    nationalLength: 10,
    bounds: CountryBounds(24.4, 49.4, -125.0, -66.9),
  );

  /// البلد الافتراضي للتطبيق (بيستخدم للصيغة المحلية اللي بدون كود دولة).
  static const CountryInfo defaultCountry = egypt;

  static const List<CountryInfo> all = [
    egypt,
    saudiArabia,
    uae,
    kuwait,
    qatar,
    bahrain,
    oman,
    jordan,
    palestine,
    iraq,
    libya,
    sudan,
    morocco,
    algeria,
    tunisia,
    turkey,
    unitedKingdom,
    germany,
    france,
    usa,
  ];

  static CountryInfo? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final country in all) {
      if (country.code == code.toUpperCase()) return country;
    }
    return null;
  }

  /// بيرجّع البلد صاحب أطول كود اتصال مطابق (علشان 212 المغرب مش 2).
  static CountryInfo? byDialCode(String digits) {
    if (digits.isEmpty) return null;
    CountryInfo? match;
    for (final country in all) {
      if (!digits.startsWith(country.dialCode)) continue;
      if (match == null || country.dialCode.length > match.dialCode.length) {
        match = country;
      }
    }
    return match;
  }

  static CountryInfo? byCoordinates(double? lat, double? lng) {
    if (!isValidPoint(lat, lng)) return null;
    for (final country in all) {
      final bounds = country.bounds;
      if (bounds != null && bounds.contains(lat!, lng!)) return country;
    }
    return null;
  }

  /// استنتاج البلد من رقم مكتوب بصيغة محلية أو دولية.
  ///
  /// الأرقام المحلية اللي بتبدأ بصفر بتتنسب لـ [fallback] (مصر افتراضيًا).
  static CountryInfo? fromPhone(String? raw, {CountryInfo? fallback}) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;

    var digits = digitsOf(text);
    if (digits.isEmpty) return null;

    final explicitInternational = text.startsWith('+') || digits.startsWith('00');
    if (digits.startsWith('00')) digits = digits.substring(2);

    if (explicitInternational) {
      return byDialCode(digits) ?? fallback;
    }

    if (text.startsWith('0')) return fallback ?? defaultCountry;

    final byDial = byDialCode(digits);
    if (byDial != null && digits.length > byDial.dialCode.length) {
      var national = digits.substring(byDial.dialCode.length);
      if (national.startsWith('0')) national = national.substring(1);
      if (byDial.acceptsNationalLength(national.length)) return byDial;
    }

    return fallback ?? defaultCountry;
  }

  /// أقصى عدد أرقام مسموح في حقل الموبايل حسب الصيغة المكتوبة.
  ///
  /// - `+966...`: كود الدولة + الرقم الوطني.
  /// - `0020...`: زيادة 2 للأصفار الدولية.
  /// - `010...`: طول الصيغة المحلية (بصفر البداية).
  /// - رقم وطني مباشر: عدد أرقام البلد الوطني.
  static int maxInputDigits(String raw, {CountryInfo? fallback}) {
    final text = raw.trim();
    final country = fromPhone(text, fallback: fallback) ?? fallback ?? defaultCountry;
    final digits = digitsOf(text);

    if (digits.startsWith('00')) return country.maxPhoneDigits + 2;
    if (text.startsWith('+')) return country.maxPhoneDigits;
    if (text.startsWith('0')) {
      return country.localLength ?? country.nationalLength + 1;
    }
    if (digits.startsWith(country.dialCode) &&
        digits.length > country.maxNationalLength) {
      return country.dialCode.length + country.maxNationalLength;
    }
    return country.maxNationalLength;
  }

  /// بيحوّل الرقم لصيغة دولية موحّدة (+2010...) قبل تخزينه.
  static String normalizePhone(String raw, {CountryInfo? fallback}) {
    final text = raw.trim();
    if (text.isEmpty) return '';

    final country = fromPhone(text, fallback: fallback) ?? fallback ?? defaultCountry;
    var digits = digitsOf(text);
    if (digits.isEmpty) return text;

    final explicitInternational = text.startsWith('+') || digits.startsWith('00');
    if (digits.startsWith('00')) digits = digits.substring(2);

    if (explicitInternational) {
      if (digits.startsWith(country.dialCode)) {
        digits = digits.substring(country.dialCode.length);
      }
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    } else if (digits.startsWith(country.dialCode) &&
        digits.length > country.maxNationalLength) {
      digits = digits.substring(country.dialCode.length);
    }

    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.isEmpty) return text;
    return '+${country.dialCode}$digits';
  }

  /// كل الأرقام الموجودة في النص.
  static String digitsOf(String value) => value.replaceAll(RegExp(r'\D'), '');

  static bool isValidPoint(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}

/// بيحدد عدد أرقام حقل الموبايل أثناء الكتابة حسب البلد.
class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter({this.country = Countries.egypt});

  final CountryInfo country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digits = Countries.digitsOf(newValue.text);
    final maxDigits = Countries.maxInputDigits(newValue.text, fallback: country);
    if (digits.length > maxDigits) return oldValue;
    return newValue;
  }
}
