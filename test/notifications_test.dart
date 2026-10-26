// اختبار الإشعارات: كل حساب لازم يشوف إشعاراته هو بس.
import 'dart:async';

import 'package:delivery_elbalad/core/result/result.dart';
import 'package:delivery_elbalad/features/auth/domain/entities/app_user.dart';
import 'package:delivery_elbalad/features/notifications/data/notification_service.dart';
import 'package:delivery_elbalad/features/notifications/data/order_status_watcher.dart';
import 'package:delivery_elbalad/features/notifications/domain/app_notification.dart';
import 'package:delivery_elbalad/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:delivery_elbalad/features/orders/domain/entities/order.dart';
import 'package:delivery_elbalad/features/orders/domain/repositories/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// طلب تجريبي بسيط.
Order buildOrder({
  OrderStatus status = OrderStatus.pendingSeller,
  bool offered = false,
}) {
  return Order(
    id: 'o-1',
    code: '#250101-ABCD',
    buyerId: 'buyer-1',
    buyerName: 'أحمد محمود',
    sellerId: 'seller-1',
    sellerName: 'سوبر ماركت البلد',
    courierId: offered ? null : 'courier-1',
    courierName: 'محمود الدليفاري',
    offeredCourierId: offered ? 'courier-1' : null,
    status: status,
    paymentMethod: PaymentMethod.cashOnDelivery,
    paymentStatus: PaymentStatus.unpaid,
    itemsSubtotal: 100,
    deliveryFee: 20,
    total: 120,
    addressLabel: 'البيت',
    addressDetails: 'شبين الكوم - شارع الجيش',
    addressLat: 30.5,
    addressLng: 31.2,
    storeLat: 30.5528,
    storeLng: 31.0058,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

/// مستودع وهمي: بيرجّع الطلبات وبيبعت تحديثات الحالة.
class _FakeOrders {
  _FakeOrders(this.orders);

  List<Order> orders;
  final StreamController<Result<Order>> controller =
      StreamController<Result<Order>>.broadcast();

  void emit(Order order) => controller.add(Result<Order>.success(order));
}

class _FakeBuyerOrderRepository implements OrderRepository {
  _FakeBuyerOrderRepository(this.fake);

  final _FakeOrders fake;

  @override
  Future<Result<List<Order>>> buyerOrders(String buyerId) async =>
      Result<List<Order>>.success(fake.orders);

  @override
  Stream<Result<Order>> watchOrder(String orderId) => fake.controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSellerOrderRepository implements SellerOrderRepository {
  _FakeSellerOrderRepository(this.fake);

  final _FakeOrders fake;

  @override
  Future<Result<List<Order>>> sellerOrders(String sellerId) async =>
      Result<List<Order>>.success(fake.orders);

  @override
  Stream<Result<Order>> watchOrder(String orderId) => fake.controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCourierOrderRepository implements CourierOrderRepository {
  _FakeCourierOrderRepository(this.fake, {this.offers = const []});

  final _FakeOrders fake;
  final List<Order> offers;

  @override
  Future<Result<List<Order>>> courierOrders(String courierId,
      {bool onlyActive = false}) async =>
      Result<List<Order>>.success(fake.orders);

  @override
  Future<Result<List<Order>>> offeredOrders(String courierId) async =>
      Result<List<Order>>.success(offers);

  @override
  Stream<Result<Order>> watchOrder(String orderId) => fake.controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// خدمة إشعارات وهمية (من غير نظام التشغيل).
class _FakeNotificationService extends NotificationService {
  int calls = 0;
  int cancelCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> show({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    calls++;
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
  }
}

void main() {
  test('تغيير حالة الطلب بيوصل إشعار لصاحب الحساب بس', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = NotificationsCubit(preferences);
    addTearDown(cubit.close);

    final fake = _FakeOrders([buildOrder()]);
    final service = _FakeNotificationService();
    final watcher = OrderStatusWatcher(
      buyerOrders: _FakeBuyerOrderRepository(fake),
      sellerOrders: _FakeSellerOrderRepository(fake),
      courierOrders: _FakeCourierOrderRepository(fake),
      notifications: cubit,
      service: service,
    );
    addTearDown(watcher.stop);

    const buyer = AppUser(
      id: 'buyer-1',
      fullName: 'أحمد محمود',
      email: 'buyer@elbalad.app',
      role: UserRole.buyer,
    );

    await watcher.start(buyer);
    expect(cubit.state.items, isEmpty);

    // المتجر قبل الطلب (الجديد).
    fake.emit(buildOrder(status: OrderStatus.confirmed));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // صاحب الحساب (المشتري) بس هو اللي بيوصله إشعار.
    expect(cubit.state.forUser(UserRole.buyer, 'buyer-1').length, 1);
    expect(cubit.state.forUser(UserRole.seller, 'seller-1'), isEmpty);
    expect(cubit.state.forUser(UserRole.courier, 'courier-1'), isEmpty);
    expect(service.calls, 1);

    // الطيار استلم الطلب → المشتري بس برضه.
    fake.emit(buildOrder(status: OrderStatus.pickedUp));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.forUser(UserRole.buyer, 'buyer-1').length, 2);
    expect(cubit.state.forUser(UserRole.seller, 'seller-1'), isEmpty);
    expect(cubit.state.forUser(UserRole.courier, 'courier-1'), isEmpty);
    expect(service.calls, 2);

    // إشعار حساب تاني على نفس الجهاز مايظهرش للمشتري.
    cubit.push(AppNotification(
      id: 'seller-only',
      role: UserRole.seller,
      title: 'طلب جديد',
      body: 'في طلب جديد',
      createdAt: DateTime.now(),
      orderId: 'o-2',
      recipientId: 'seller-1',
    ));
    expect(cubit.state.forUser(UserRole.buyer, 'buyer-1').length, 2);
    expect(cubit.state.forUser(UserRole.seller, 'seller-1').length, 1);

    // نفس الدور لكن حساب مختلف مايشوفش إشعارات المشتري.
    expect(cubit.state.forUser(UserRole.buyer, 'buyer-2'), isEmpty);

    // الإشعارات بتتحفظ في التفضيلات.
    expect(preferences.getString('app_notifications'), isNotNull);

    // تعليم الكل كمقروء للحساب الحالي بس.
    cubit.markAllRead(UserRole.buyer, 'buyer-1');
    expect(cubit.state.unreadFor(UserRole.buyer, 'buyer-1'), 0);
    expect(cubit.state.unreadFor(UserRole.seller, 'seller-1'), 1);

    fake.controller.close();
  });

  test('عرض الطلب مايوصلش لطيار قفل الاستلام', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = NotificationsCubit(preferences);
    addTearDown(cubit.close);

    final fake = _FakeOrders(const []);
    final offer = buildOrder(status: OrderStatus.readyForPickup, offered: true);
    final service = _FakeNotificationService();
    final watcher = OrderStatusWatcher(
      buyerOrders: _FakeBuyerOrderRepository(fake),
      sellerOrders: _FakeSellerOrderRepository(fake),
      courierOrders: _FakeCourierOrderRepository(fake, offers: [offer]),
      notifications: cubit,
      service: service,
    );
    addTearDown(watcher.stop);

    const courier = AppUser(
      id: 'courier-1',
      fullName: 'محمود الدليفاري',
      email: 'courier@elbalad.app',
      role: UserRole.courier,
      phone: '01098765432',
      lat: 30.5580,
      lng: 31.0140,
      isAvailable: true,
    );

    await watcher.start(courier);

    // الطيار قفل الاستلام → مفيش إشعار لعرض الطلب.
    watcher.updateUser(courier.copyWith(isAvailable: false));
    fake.emit(offer.copyWith(status: OrderStatus.assigned));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.items, isEmpty);
    expect(service.calls, 0);

    // رجع متاح تاني → الإشعار بيوصل لصاحب الحساب.
    watcher.updateUser(courier);
    fake.emit(offer.copyWith(status: OrderStatus.pickedUp));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.forUser(UserRole.courier, 'courier-1').length, 1);
    expect(service.calls, 1);

    fake.controller.close();
  });
}
