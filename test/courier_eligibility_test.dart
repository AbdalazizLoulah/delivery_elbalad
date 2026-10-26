// اختبارات أهلية الطيار: متاح + قريب من المتجر + نفس بلد العميل.
import 'package:delivery_elbalad/features/auth/domain/entities/app_user.dart';
import 'package:delivery_elbalad/features/delivery/domain/courier_eligibility.dart';
import 'package:delivery_elbalad/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

const _courier = AppUser(
  id: 'courier-1',
  fullName: 'محمود الدليفاري',
  email: 'courier@elbalad.app',
  role: UserRole.courier,
  phone: '01098765432',
  lat: 30.5580,
  lng: 31.0140,
  isAvailable: true,
);

Order _order({
  double storeLat = 30.5528,
  double storeLng = 31.0058,
  double addressLat = 30.5566,
  double addressLng = 31.0106,
  String buyerPhone = '01012345678',
}) {
  return Order(
    id: 'o-1',
    code: '#250101-ABCD',
    buyerId: 'buyer-1',
    buyerName: 'أحمد محمود',
    buyerPhone: buyerPhone,
    sellerId: 'seller-1',
    sellerName: 'سوبر ماركت البلد',
    status: OrderStatus.readyForPickup,
    paymentMethod: PaymentMethod.cashOnDelivery,
    paymentStatus: PaymentStatus.unpaid,
    itemsSubtotal: 100,
    deliveryFee: 20,
    total: 120,
    addressLabel: 'البيت',
    addressDetails: 'شبين الكوم - شارع الجيش',
    addressLat: addressLat,
    addressLng: addressLng,
    storeLat: storeLat,
    storeLng: storeLng,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('أهلية الطيار للطلب', () {
    test('طيار متاح وقريب من المتجر => الطلب يظهر', () {
      expect(
        CourierEligibility.canServe(courier: _courier, order: _order()),
        isTrue,
      );
    });

    test('طيار موقف استلام الطلبات => الطلب مايظهرش', () {
      final unavailable = _courier.copyWith(isAvailable: false);
      expect(
        CourierEligibility.canServe(courier: unavailable, order: _order()),
        isFalse,
      );
    });

    test('طيار بعيد عن المتجر => الطلب مايظهرش', () {
      expect(
        CourierEligibility.canServe(
          courier: _courier,
          order: _order(),
          lat: 31.20,
          lng: 31.50,
        ),
        isFalse,
      );
    });

    test('طلب من غير موقع متجر => الطلب مايظهرش', () {
      final order = Order(
        id: 'o-2',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        status: OrderStatus.readyForPickup,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentStatus: PaymentStatus.unpaid,
        itemsSubtotal: 10,
        deliveryFee: 5,
        total: 15,
        addressLabel: 'البيت',
        addressDetails: 'شبين الكوم',
        addressLat: 30.5566,
        addressLng: 31.0106,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(
        CourierEligibility.canServe(courier: _courier, order: order),
        isFalse,
      );
    });

    test('طيار من بلد تاني => الطلب مايظهرش', () {
      final otherCountryCourier = _courier.copyWith(
        phone: '+966501234567',
        lat: 24.7136,
        lng: 46.6753,
      );
      expect(
        CourierEligibility.canServe(
          courier: otherCountryCourier,
          order: _order(),
        ),
        isFalse,
      );
    });
  });
}
