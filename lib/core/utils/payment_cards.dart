import 'package:flutter/services.dart';

/// نوع كارت الدفع (بيتحدد من أول أرقام الكارت).
enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  meeza,
  unionPay,
  unknown;

  String get labelAr => switch (this) {
        CardBrand.visa => 'فيزا',
        CardBrand.mastercard => 'ماستركارد',
        CardBrand.amex => 'أمريكان إكسبريس',
        CardBrand.discover => 'ديسكفر',
        CardBrand.meeza => 'ميزة',
        CardBrand.unionPay => 'يونيون باي',
        CardBrand.unknown => 'كارت',
      };
}

/// قواعد أطوال أكواد الكروت المعروفة (Visa / Mastercard / Meeza ...).
class CardRules {
  const CardRules._();

  static List<int> validLengths(CardBrand brand) => switch (brand) {
        CardBrand.visa => const [13, 16, 19],
        CardBrand.mastercard => const [16],
        CardBrand.amex => const [15],
        CardBrand.discover => const [16, 19],
        CardBrand.meeza => const [16],
        CardBrand.unionPay => const [16, 17, 18, 19],
        CardBrand.unknown => const [13, 14, 15, 16, 17, 18, 19],
      };

  /// أطول طول مسموح للكارت حسب نوعه (بيستخدم في منع الزيادة أثناء الكتابة).
  static int maxLength(String digits) =>
      validLengths(detect(digits)).reduce((a, b) => a > b ? a : b);

  static CardBrand detect(String digits) {
    if (digits.isEmpty) return CardBrand.unknown;

    if (digits.startsWith('4')) return CardBrand.visa;

    final prefix2 = int.tryParse(digits.length >= 2 ? digits.substring(0, 2) : digits);
    if (prefix2 != null && prefix2 >= 51 && prefix2 <= 55) {
      return CardBrand.mastercard;
    }
    final prefix4 = int.tryParse(digits.length >= 4 ? digits.substring(0, 4) : digits);
    if (prefix4 != null) {
      if (prefix4 >= 2221 && prefix4 <= 2720) return CardBrand.mastercard;
      if (prefix4 >= 6440 && prefix4 <= 6499) return CardBrand.discover;
      if (prefix4 == 6011) return CardBrand.discover;
      if (prefix4 >= 5078 && prefix4 <= 5080) return CardBrand.meeza;
    }
    final prefix6 = int.tryParse(digits.length >= 6 ? digits.substring(0, 6) : digits);
    if (prefix6 != null && prefix6 >= 622126 && prefix6 <= 622925) {
      return CardBrand.discover;
    }

    if (digits.startsWith('34') || digits.startsWith('37')) return CardBrand.amex;
    if (digits.startsWith('65')) return CardBrand.discover;
    if (digits.startsWith('62')) return CardBrand.unionPay;

    return CardBrand.unknown;
  }

  /// تحقق Luhn + الطول المعروف لنوع الكارت.
  static bool isValid(String digits) {
    if (digits.length < 13 || digits.length > 19) return false;
    if (!validLengths(detect(digits)).contains(digits.length)) return false;
    if (digits.split('').toSet().length <= 1) return false;
    return _passesLuhn(digits);
  }

  static bool _passesLuhn(String digits) {
    var sum = 0;
    var doubleIt = false;
    for (var index = digits.length - 1; index >= 0; index--) {
      var digit = int.tryParse(digits[index]);
      if (digit == null) return false;
      if (doubleIt) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  static String digitsOf(String value) => value.replaceAll(RegExp(r'\D'), '');
}

/// بيمنع كتابة أرقام زيادة عن طول الكارت المعروف (Visa 19 / Amex 15 ...).
class CardNumberInputFormatter extends TextInputFormatter {
  const CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = CardRules.digitsOf(newValue.text);
    if (digits.length > CardRules.maxLength(digits)) return oldValue;
    return newValue;
  }
}

/// تاريخ الانتهاء MM/YY: أقصى 4 أرقام + السماح بالشرطة المائلة.
class CardExpiryInputFormatter extends TextInputFormatter {
  const CardExpiryInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (CardRules.digitsOf(newValue.text).length > 4) return oldValue;
    return newValue;
  }
}

/// CVV: من 3 لـ 4 أرقام فقط.
class CardCvvInputFormatter extends TextInputFormatter {
  const CardCvvInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = CardRules.digitsOf(newValue.text);
    if (digits.length > 4) return oldValue;
    return newValue.copyWith(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
