import 'package:delivery_elbalad/features/orders/data/models/order_model.dart';
import 'package:delivery_elbalad/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('صف عنصر الطلب لازم يحتوي على id (عمود id إلزامي في Supabase)', () {
    const item = OrderItemModel(
      id: 'item-1',
      productId: 'product-1',
      title: 'طماطم',
      unitPrice: 15,
      quantity: 2,
    );

    final row = item.toJson('order-1');

    expect(row['id'], 'item-1');
    expect(row['order_id'], 'order-1');
    expect(row['product_id'], 'product-1');
    expect(row['quantity'], 2);
  });

  group('إلغاء الطيار للطلب', () {
    Order order({
      required PaymentMethod method,
      required PaymentStatus status,
      OrderStatus orderStatus = OrderStatus.assigned,
    }) {
      return Order(
        id: 'order-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        status: orderStatus,
        paymentMethod: method,
        paymentStatus: status,
        itemsSubtotal: 100,
        deliveryFee: 15,
        total: 115,
        addressLabel: 'المنزل',
        addressDetails: 'شبين الكوم',
        addressLat: 30.55,
        addressLng: 31.01,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('الدفع عند الاستلام => الطيار يقدر يلغي', () {
      final cash = order(
        method: PaymentMethod.cashOnDelivery,
        status: PaymentStatus.unpaid,
      );
      expect(cash.canCourierCancel, isTrue);
    });

    test('مدفوع أونلاين => ممنوع الإلغاء', () {
      final card = order(
        method: PaymentMethod.visa,
        status: PaymentStatus.paid,
      );
      expect(card.canCourierCancel, isFalse);
    });

    test('طلب مقفول (اتسلّم) => ممنوع الإلغاء', () {
      final delivered = order(
        method: PaymentMethod.cashOnDelivery,
        status: PaymentStatus.paid,
        orderStatus: OrderStatus.delivered,
      );
      expect(delivered.canCourierCancel, isFalse);
    });
  });
}
