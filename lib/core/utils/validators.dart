import 'countries.dart';
import 'payment_cards.dart';

class Validators {
  const Validators._();

  static String? required(String? value, {String message = 'الحقل دا مطلوب'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'اكتب البريد الإلكتروني';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!regex.hasMatch(value.trim())) return 'صيغة البريد الإلكتروني غير صحيحة';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'اكتب كلمة السر';
    if (value.length < 6) return 'كلمة السر لازم 6 حروف على الأقل';
    return null;
  }

  /// تحقق من رقم الموبايل بعدد الأرقام الرسمي للبلد.
  ///
  /// [country] هي البلد المختارة في الواجهة (مصر افتراضيًا). لو الرقم مكتوب
  /// بصيغة دولية (+966...) بنستخدم كود الاتصال المكتوب نفسه.
  static String? phone(String? value, {CountryInfo? country}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'اكتب رقم الموبايل';

    final fallback = country ?? Countries.defaultCountry;
    final digits = Countries.digitsOf(text);
    if (digits.isEmpty) return 'رقم الموبايل غير صحيح';

    final resolved = Countries.fromPhone(text, fallback: fallback) ?? fallback;
    final explicitInternational = text.startsWith('+') || digits.startsWith('00');

    var national = digits;
    if (national.startsWith('00')) national = national.substring(2);

    if (explicitInternational) {
      if (!national.startsWith(resolved.dialCode)) return 'رقم الموبايل غير صحيح';
      national = national.substring(resolved.dialCode.length);
    } else if (!text.startsWith('0') &&
        national.startsWith(resolved.dialCode) &&
        national.length > resolved.maxNationalLength) {
      national = national.substring(resolved.dialCode.length);
    }

    if (national.startsWith('0')) national = national.substring(1);

    if (national.isEmpty) return 'رقم الموبايل غير صحيح';
    if (!resolved.acceptsNationalLength(national.length)) {
      return 'رقم الموبايل غير صحيح';
    }
    if (national.split('').toSet().length <= 1) return 'رقم الموبايل غير صحيح';
    return null;
  }

  static String? cardNumber(String? value) {
    final digits = CardRules.digitsOf(value ?? '');
    if (digits.isEmpty) return 'اكتب رقم الكارت';
    if (!CardRules.isValid(digits)) return 'رقم الكارت غير صحيح';
    return null;
  }

  static String? cardExpiry(String? value) {
    final text = (value ?? '').trim();
    final match = RegExp(r'^(\d{2})\s*/\s*(\d{2})$').firstMatch(text);
    if (match == null) return 'الصيغة الصحيحة MM/YY';
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return 'شهر غير صحيح';

    final year = 2000 + int.parse(match.group(2)!);
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1, 1);
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    if (!expiry.isAfter(startOfCurrentMonth)) return 'الكارت منتهي الصلاحية';
    return null;
  }

  static String? cardCvv(String? value) {
    final digits = CardRules.digitsOf(value ?? '');
    if (digits.length < 3 || digits.length > 4) return 'CVV غير صحيح';
    return null;
  }
}
