// اختبارات أساسية للوحدات المساعدة (مصاريف الدليفاري + حساب المسافات).
import 'package:delivery_elbalad/core/config/app_config.dart';
import 'package:delivery_elbalad/core/utils/distance_calculator.dart';
import 'package:delivery_elbalad/core/utils/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('مصاريف الدليفاري', () {
    test('بتبدأ بالقيمة الثابتة لو المسافة صفر', () {
      expect(Pricing.deliveryFee(0), AppConfig.baseDeliveryFee);
    });

    test('بتزيد بسعر الكيلومتر', () {
      expect(Pricing.deliveryFee(2), AppConfig.baseDeliveryFee + (2 * AppConfig.perKmDeliveryFee));
    });

    test('مش بتعدي الحد الأقصى', () {
      expect(Pricing.deliveryFee(500), AppConfig.maxDeliveryFee);
    });
  });

  group('حساب المسافات', () {
    test('نفس النقطة = صفر', () {
      final distance = DistanceCalculator.betweenKm(
        fromLat: 30.5566,
        fromLng: 31.0106,
        toLat: 30.5566,
        toLng: 31.0106,
      );
      expect(distance, closeTo(0, 0.0001));
    });

    test('المسافة بين متجر البلد وجامعة المنوفية معقولة', () {
      final distance = DistanceCalculator.betweenKm(
        fromLat: 30.5528,
        fromLng: 31.0058,
        toLat: 30.5420,
        toLng: 31.0170,
      );
      expect(distance, greaterThan(1));
      expect(distance, lessThan(3));
    });
  });
}
