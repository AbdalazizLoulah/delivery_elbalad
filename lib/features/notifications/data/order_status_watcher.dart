import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../delivery/domain/courier_eligibility.dart';
import '../../orders/domain/entities/order.dart';
import '../../orders/domain/repositories/order_repository.dart';
import '../domain/app_notification.dart';
import '../presentation/bloc/notifications_cubit.dart';
import 'notification_service.dart';

/// بيتابع طلبات المستخدم الحالي وبيولّد إشعار لصاحب الحساب ده بس.
///
/// كل إشعار بيتخزّن بـ recipientId، والواجهة بتفلتر بالـ id + الدور،
/// فمفيش حساب تاني بيشوف إشعارات مش بتاعته على نفس الجهاز.
class OrderStatusWatcher {
  OrderStatusWatcher({
    required this.buyerOrders,
    required this.sellerOrders,
    required this.courierOrders,
    required this.notifications,
    required this.service,
  });

  final OrderRepository buyerOrders;
  final SellerOrderRepository sellerOrders;
  final CourierOrderRepository courierOrders;
  final NotificationsCubit notifications;
  final NotificationService service;

  final Map<String, OrderStatus> _lastStatus = {};
  final Map<String, StreamSubscription<Result<Order>>> _subscriptions = {};
  Timer? _timer;
  AppUser? _user;

  /// أقصى عدد طلبات بنراقبها في نفس الوقت.
  static const int _maxWatchedOrders = 10;

  /// يبدأ مراقبة طلبات المستخدم (وبيشيل المراقبة القديمة).
  Future<void> start(AppUser user) async {
    await stop();
    _user = user;
    // بنطلب إذن الإشعارات أول ما المستخدم يدخل (Once).
    unawaited(service.init());
    await _syncOrders();
    // تحديث دوري: لو اتعمل طلب جديد بعد ما بدأنا، هنلحقه.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _syncOrders());
  }

  /// يحدّث بيانات نفس الحساب (الاتاحة / الموقع) من غير ما نعيد فتح المراقبة.
  void updateUser(AppUser user) {
    if (_user?.id == user.id) _user = user;
  }

  /// بيوقف المراقبة (لما المستخدم يطلع أو يتبدّل).
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    // بننسخ القائمة الأول عشان ممكن يتغيّر أثناء الإلغاء (من داخل الكولباك).
    final subscriptions = _subscriptions.values.toList();
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    _lastStatus.clear();
    _user = null;
  }

  Future<void> _syncOrders() async {
    final user = _user;
    if (user == null) return;

    final orders = await _ordersOf(user);
    for (final order in orders) {
      if (_subscriptions.containsKey(order.id)) continue;
      _lastStatus[order.id] = order.status;
      _subscribe(order.id);
    }
  }

  Future<List<Order>> _ordersOf(AppUser user) async {
    try {
      final result = switch (user.role) {
        UserRole.buyer => await buyerOrders.buyerOrders(user.id),
        UserRole.seller => await sellerOrders.sellerOrders(user.id),
        UserRole.courier => await courierOrders.courierOrders(user.id),
      };
      if (!result.isSuccess || result.data == null) return const [];
      // بنراقب أحدث الطلبات النشطة بس (عشان ما نفتحش سطور كتير).
      final orders = <String, Order>{
        for (final order in result.data!) order.id: order,
      };

      // الطيار كمان بيستقبل طلبات معروضة عليه (الأقرب ليه)، بشرط إنه
      // متاح وقريب من المتجر وفي نفس بلد العميل — نفس شروط ظهور الطلب.
      if (user.role == UserRole.courier && user.isAvailable) {
        final offered = await courierOrders.offeredOrders(user.id);
        if (offered.isSuccess && offered.data != null) {
          for (final order in offered.data!) {
            if (CourierEligibility.canServe(courier: user, order: order)) {
              orders[order.id] = order;
            }
          }
        }
      }

      final active = orders.values.where((order) => order.status.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (active.length <= _maxWatchedOrders) return active;
      return active.sublist(0, _maxWatchedOrders);
    } catch (error) {
      debugPrint('تعذر تحميل الطلبات للمراقبة: $error');
      return const [];
    }
  }

  void _subscribe(String orderId) {
    final stream = switch (_user?.role) {
      UserRole.buyer => buyerOrders.watchOrder(orderId),
      UserRole.seller => sellerOrders.watchOrder(orderId),
      UserRole.courier => courierOrders.watchOrder(orderId),
      null => const Stream<Result<Order>>.empty(),
    };

    _subscriptions[orderId] = stream.listen((result) {
      if (!result.isSuccess || result.data == null) return;
      final order = result.data!;
      final previous = _lastStatus[order.id];
      if (previous == null) {
        _lastStatus[order.id] = order.status;
        return;
      }
      if (previous == order.status) return;
      _lastStatus[order.id] = order.status;
      _announce(order);
      if (order.status.isFinal) {
        _subscriptions[order.id]?.cancel();
        _subscriptions.remove(order.id);
      }
    });
  }

  /// يبني إشعار الطرف الحالي بس — مش كل الأطراف.
  ///
  /// كل جهاز بيشغّل watcher لحساب واحد، فلازم الإشعار يتخزّن ويعرض
  /// لصاحب الحساب ده فقط (recipientId + role)، مش لأي مستخدم تاني.
  void _announce(Order order) {
    final user = _user;
    if (user == null) return;

    // عرض طلب لسه ماتعيّنش لطيار: لو الطيار قفل الاستلام أو بقى بعيد/خارج
    // بلد الطلب، مفيش إشعار يتعرض عليه.
    final isOffer = order.courierId == null && order.offeredCourierId != null;
    if (user.role == UserRole.courier &&
        isOffer &&
        (!user.isAvailable ||
            !CourierEligibility.canServe(courier: user, order: order))) {
      return;
    }

    final notificationsToSend = <AppNotification?>[
      _buildNotification(
        order: order,
        role: UserRole.buyer,
        recipientId: order.buyerId,
        body: _buyerMessage(order.status),
      ),
      _buildNotification(
        order: order,
        role: UserRole.seller,
        recipientId: order.sellerId,
        body: _sellerMessage(order.status),
      ),
      _buildNotification(
        order: order,
        role: UserRole.courier,
        recipientId: order.courierId ?? order.offeredCourierId,
        body: _courierMessage(order.status),
      ),
    ];

    for (final notification in notificationsToSend) {
      if (notification == null) continue;
      _push(notification: notification, order: order);
    }
  }

  AppNotification? _buildNotification({
    required Order order,
    required UserRole role,
    required String? recipientId,
    required String? body,
  }) {
    final user = _user;
    if (user == null || body == null) return null;
    if (user.role != role || recipientId != user.id) return null;
    return AppNotification(
      id: '${order.id}-${order.status.name}-${role.name}',
      role: role,
      title: 'طلب ${order.code}',
      body: body,
      createdAt: DateTime.now(),
      orderId: order.id,
      recipientId: recipientId,
    );
  }

  void _push({required AppNotification notification, required Order order}) {
    notifications.push(notification);
    service.show(
      title: notification.title,
      body: notification.body,
      payload: order.id,
      id: order.id.hashCode & 0x7fffffff,
    );
  }

  String? _buyerMessage(OrderStatus status) => switch (status) {
        OrderStatus.pendingSeller => 'بانتظار موافقة المتجر',
        OrderStatus.confirmed => 'المتجر قبل الطلب',
        OrderStatus.preparing => 'جاري التجهيز',
        OrderStatus.readyForPickup => 'جاهز للاستلام',
        OrderStatus.assigned => 'طيار في الطريق للمتجر',
        OrderStatus.pickedUp => 'الطيار استلم الطلب',
        OrderStatus.onTheWay => 'في الطريق إليك',
        OrderStatus.delivered => 'تم التسليم',
        OrderStatus.cancelled => 'الطلب اتلغى',
      };

  String? _sellerMessage(OrderStatus status) => switch (status) {
        OrderStatus.pendingSeller => 'طلب جديد',
        OrderStatus.confirmed => 'المتجر قبل الطلب',
        OrderStatus.preparing => 'جاري تجهيز الطلب',
        OrderStatus.readyForPickup => 'الطلب جاهز للاستلام',
        OrderStatus.assigned => 'تم تعيين الطيار للطلب',
        OrderStatus.pickedUp => 'الطيار استلم الطلب من المتجر',
        OrderStatus.onTheWay => 'الطلب في الطريق للعميل',
        OrderStatus.delivered => 'تم تسليم الطلب',
        OrderStatus.cancelled => 'المتجر ألغى الطلب',
      };

  String? _courierMessage(OrderStatus status) => switch (status) {
        OrderStatus.readyForPickup => 'الطلب جاهز للاستلام',
        OrderStatus.assigned => 'تم تعيين الطيار للطلب',
        OrderStatus.pickedUp => 'استلمت الطلب من المتجر',
        OrderStatus.onTheWay => 'الطلب في الطريق للعميل',
        OrderStatus.delivered => 'تم تسليم الطلب',
        OrderStatus.cancelled => 'الطلب اتلغى',
        _ => null,
      };
}
