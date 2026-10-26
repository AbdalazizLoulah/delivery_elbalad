// اختبارات أرقام الموبايل حسب البلد وأرقام الكروت.
import 'package:delivery_elbalad/core/utils/countries.dart';
import 'package:delivery_elbalad/core/utils/payment_cards.dart';
import 'package:delivery_elbalad/core/utils/validators.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('أرقام الموبايل حسب البلد', () {
    test('رقم مصري محلي صحيح', () {
      expect(Validators.phone('01012345678'), isNull);
      expect(Validators.phone('01112345678', country: Countries.egypt), isNull);
    });

    test('رقم مصري زيادة أو ناقص بيترفض', () {
      expect(Validators.phone('010123456789'), isNotNull);
      expect(Validators.phone('0101234567'), isNotNull);
    });

    test('الصيغة الدولية لمصر مقبولة', () {
      expect(Validators.phone('+20 10 1234 5678'), isNull);
      expect(Validators.phone('00201012345678'), isNull);
    });

    test('رقم سعودي بعدد أرقام السعودية', () {
      expect(Validators.phone('+966501234567'), isNull);
      expect(Validators.phone('+96650123456'), isNotNull);
    });

    test('استنتاج البلد من كود الاتصال', () {
      expect(Countries.fromPhone('+966501234567')?.code, 'SA');
      expect(Countries.fromPhone('01012345678')?.code, 'EG');
      expect(Countries.byCoordinates(30.55, 31.01)?.code, 'EG');
    });

    test('محول الإدخال بيمنع الزيادة عن أرقام البلد', () {
      const formatter = PhoneNumberInputFormatter();
      const oldValue = TextEditingValue(text: '01012345678');
      final tooLong = oldValue.copyWith(text: '010123456789');
      expect(formatter.formatEditUpdate(oldValue, tooLong).text, oldValue.text);
    });

    test('الرقم الوطني بدون صفر البداية بيتقيد بعدد أرقام البلد', () {
      expect(Countries.maxInputDigits('501234567', fallback: Countries.saudiArabia), 9);
      expect(Countries.maxInputDigits('0501234567', fallback: Countries.saudiArabia), 10);
      expect(
        Countries.maxInputDigits('966501234567', fallback: Countries.saudiArabia),
        12,
      );
    });

    test('الصيغة الدولية 00 بتسمح بكود الدولة + الرقم كامل', () {
      final formatter = const PhoneNumberInputFormatter();
      var value = const TextEditingValue();
      for (final char in '00201012345678'.split('')) {
        final next = value.copyWith(
          text: '${value.text}$char',
          selection: TextSelection.collapsed(offset: value.text.length + 1),
        );
        value = formatter.formatEditUpdate(value, next);
      }
      expect(value.text, '00201012345678');
    });

    test('التخزين بيحوّل الرقم للصيغة الدولية', () {
      expect(
        Countries.normalizePhone('01012345678', fallback: Countries.egypt),
        '+201012345678',
      );
      expect(
        Countries.normalizePhone('0501234567', fallback: Countries.saudiArabia),
        '+966501234567',
      );
    });
  });

  group('أرقام الكروت', () {
    test('فيزا 16 رقم صحيحة', () {
      expect(Validators.cardNumber('4111 1111 1111 1111'), isNull);
    });

    test('ماستركارد صحيحة', () {
      expect(Validators.cardNumber('5555555555554444'), isNull);
    });

    test('أمريكان إكسبريس 15 رقم صحيحة', () {
      expect(Validators.cardNumber('378282246310005'), isNull);
    });

    test('رقم غلط أو طول غلط بيترفض', () {
      expect(Validators.cardNumber('4111111111111112'), isNotNull);
      expect(Validators.cardNumber('411111111111111'), isNotNull);
      expect(Validators.cardNumber('37828224631000'), isNotNull);
    });

    test('طول الكارت بيتحدد حسب النوع', () {
      expect(CardRules.detect('4111'), CardBrand.visa);
      expect(CardRules.maxLength('4111'), 19);
      expect(CardRules.detect('3782'), CardBrand.amex);
      expect(CardRules.maxLength('3782'), 15);
      expect(CardRules.detect('5555'), CardBrand.mastercard);
      expect(CardRules.maxLength('5555'), 16);
      expect(CardRules.detect('5078'), CardBrand.meeza);
      expect(CardRules.maxLength('5078'), 16);
    });

    test('محول الإدخال بيمنع زيادة أرقام الكارت', () {
      const formatter = CardNumberInputFormatter();
      const oldValue = TextEditingValue(text: '4111111111111111');
      final tooLong = oldValue.copyWith(text: '41111111111111111111');
      expect(formatter.formatEditUpdate(oldValue, tooLong).text, oldValue.text);
    });

    test('تاريخ الانتهاء المنتهي بيترفض', () {
      expect(Validators.cardExpiry('12/99'), isNull);
      expect(Validators.cardExpiry('01/20'), isNotNull);
      expect(Validators.cardExpiry('13/30'), isNotNull);
      expect(Validators.cardExpiry('1/30'), isNotNull);
    });

    test('CVV من 3 لـ 4 أرقام', () {
      expect(Validators.cardCvv('123'), isNull);
      expect(Validators.cardCvv('1234'), isNull);
      expect(Validators.cardCvv('12'), isNotNull);
      expect(Validators.cardCvv('12345'), isNotNull);
    });
  });
}
