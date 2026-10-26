import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/pricing.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../delivery/domain/courier_eligibility.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_data_source.dart';
import '../models/order_model.dart';

/// عمليات طيار الدليفاري: الطلبات القريبة، القبول، تحديث الموقع والحالة.
class CourierOrderRepositoryImpl implements CourierOrderRepository {
  CourierOrderRepositoryImpl(this._dataSource);

  final OrderDataSource _dataSource;

  @override
  Future<Result<List<Order>>> availableOrders({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    return guard(() async {
      final rows = await _dataSource.availableOrders(lat: lat, lng: lng, radiusKm: radiusKm);
      return rows.map(OrderModel.fromJson).cast<Order>().toList();
    });
  }

  @override
  Future<Result<List<Order>>> offeredOrders(String courierId) {
    return guard(() async {
      final rows = await _dataSource.offeredOrders(courierId);
      return rows.map(OrderModel.fromJson).cast<Order>().toList();
    });
  }

  @override
  Future<Result<List<Order>>> courierOrders(String courierId, {bool onlyActive = false}) {
    return guard(() async {
      final rows = await _dataSource.courierOrders(courierId, onlyActive: onlyActive);
      return rows.map(OrderModel.fromJson).cast<Order>().toList();
    });
  }

  @override
  Stream<Result<Order>> watchOrder(String orderId) async* {
    try {
      await for (final row in _dataSource.watchOrder(orderId)) {
        yield Result<Order>.success(OrderModel.fromJson(row));
      }
    } catch (error, stackTrace) {
      yield Result<Order>.failure(mapError(error, stackTrace));
    }
  }

  @override
  Future<Result<Order>> acceptOrder({
    required String orderId,
    required AppUser courier,
    required double deliveryFee,
    double? lat,
    double? lng,
  }) {
    return guard(() async {
      final current = await _dataSource.order(orderId);
      if (current == null) throw const NotFoundException('الطلب غير موجود.');
      final order = OrderModel.fromJson(current);

      if (order.hasCourier && order.courierId != courier.id) {
        throw const AppException('الطلب دا خداه طيار تاني.');
      }
      if (order.status != OrderStatus.readyForPickup && order.status != OrderStatus.assigned) {
        throw const AppException('الطلب لسه مش جاهز للاستلام من المتجر.');
      }

      // حتى لو الطلب معروض على الطيار، لازم يكون متاح وقريب من المتجر
      // وفي نفس بلد العميل.
      if (!CourierEligibility.canServe(
        courier: courier,
        order: order,
        lat: lat,
        lng: lng,
      )) {
        throw const AppException('الطلب بعيد عن المتجر أو خارج نطاق بلدك.');
      }

      final distanceKm = order.distanceKm;
      final fee = distanceKm == 0 ? order.deliveryFee : Pricing.deliveryFee(distanceKm);
      final total = double.parse((order.itemsSubtotal + fee).toStringAsFixed(2));

      await _dataSource.updateOrder(orderId, {
        'courier_id': courier.id,
        'courier_name': courier.fullName,
        'courier_phone': courier.phone,
        'offered_courier_id': null,
        'status': OrderStatus.assigned.name,
        'delivery_fee': fee,
        'total': total,
      });

      await _dataSource.addEvent(
        orderId,
        status: OrderStatus.assigned.name,
        note: 'قبل الطيار الطلب وهو في الطريق للمتجر',
        actorName: courier.fullName,
      );

      final updated = await _dataSource.order(orderId);
      return OrderModel.fromJson(updated!);
    });
  }

  @override
  Future<Result<Order>> cancelOrder({
    required String orderId,
    required String actorName,
    String note = '',
  }) {
    return guard(() async {
      final current = await _dataSource.order(orderId);
      if (current == null) throw const NotFoundException('الطلب غير موجود.');
      final order = OrderModel.fromJson(current);

      if (order.status.isFinal) {
        throw const AppException('الطلب اتقفل خلاص، مش ممكن يتلغي.');
      }
      if (!order.isCash || order.isPaid) {
        throw const AppException(
          'مش ممكن تلغي الطلب دا: الإلغاء متاح للدفع عند الاستلام فقط.',
        );
      }

      await _dataSource.updateOrder(orderId, {
        'status': OrderStatus.cancelled.name,
        'offered_courier_id': null,
      });
      await _dataSource.addEvent(
        orderId,
        status: OrderStatus.cancelled.name,
        note: note.isEmpty ? 'الطيار ألغى الطلب (الدفع عند الاستلام)' : note,
        actorName: actorName,
      );

      final updated = await _dataSource.order(orderId);
      return OrderModel.fromJson(updated!);
    });
  }

  @override
  Future<Result<void>> assignCourier({
    required String orderId,
    required String courierId,
    required bool asOffer,
  }) {
    return guard(() async {
      await _dataSource.assignCourier(orderId: orderId, courierId: courierId, asOffer: asOffer);
      if (asOffer) {
        await _dataSource.addEvent(
          orderId,
          status: OrderStatus.readyForPickup.name,
          note: 'الطلب معروض على أقرب طيار متاح',
        );
      }
    });
  }

  @override
  Future<Result<Order>> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String actorName,
    String note = '',
    String? courierId,
    String? courierName,
    String? courierPhone,
    PaymentStatus? paymentStatus,
  }) {
    return guard(() async {
      final current = await _dataSource.order(orderId);
      if (current == null) throw const NotFoundException('الطلب غير موجود.');

      final now = DateTime.now();
      await _dataSource.updateOrder(orderId, {
        'status': status.name,
        if (status == OrderStatus.delivered) 'delivered_at': now.toUtc().toIso8601String(),
        if (status == OrderStatus.delivered) 'payment_status': PaymentStatus.paid.name,
        // بيانات الطيار بتتسجل مع أول تحديث حالة جاي منه.
        'courier_id': ?courierId,
        'courier_name': ?courierName,
        'courier_phone': ?courierPhone,
      });

      await _dataSource.addEvent(
        orderId,
        status: status.name,
        note: note.isEmpty ? _defaultNote(status) : note,
        actorName: actorName,
      );

      final updated = await _dataSource.order(orderId);
      return OrderModel.fromJson(updated!);
    });
  }

  @override
  Future<Result<void>> pushLocation({
    required String courierId,
    required String orderId,
    required double lat,
    required double lng,
  }) {
    return guard(() => _dataSource.pushLocation(
          courierId: courierId,
          orderId: orderId,
          lat: lat,
          lng: lng,
        ));
  }

  @override
  Stream<Result<CourierLocation>> watchCourierLocation(String courierId) async* {
    try {
      await for (final row in _dataSource.watchCourierLocation(courierId)) {
        yield Result<CourierLocation>.success(CourierLocationModel.fromJson(row));
      }
    } catch (error, stackTrace) {
      yield Result<CourierLocation>.failure(mapError(error, stackTrace));
    }
  }

  @override
  Future<Result<CourierLocation?>> courierLocation(String courierId) {
    return guard(() async {
      final row = await _dataSource.courierLocation(courierId);
      return row == null ? null : CourierLocationModel.fromJson(row);
    });
  }

  @override
  Future<Result<void>> setAvailability({
    required String courierId,
    required bool isAvailable,
    required double lat,
    required double lng,
  }) {
    return guard(() => _dataSource.setAvailability(
          courierId: courierId,
          isAvailable: isAvailable,
          lat: lat,
          lng: lng,
        ));
  }

  @override
  Future<Result<List<AppUser>>> availableCouriers() {
    return guard(() async {
      final rows = await _dataSource.availableCouriers();
      return rows.map(AppUserModel.fromJson).cast<AppUser>().toList();
    });
  }

  /// المسافة من موقع الطيار للمتجر (بتستخدم في العرض والترتيب).
  double distanceToStore({
    required double courierLat,
    required double courierLng,
    required Order order,
  }) {
    final storeLat = order.storeLat;
    final storeLng = order.storeLng;
    if (storeLat == null || storeLng == null) return 0;
    return DistanceCalculator.betweenKm(
      fromLat: courierLat,
      fromLng: courierLng,
      toLat: storeLat,
      toLng: storeLng,
    );
  }

  String _defaultNote(OrderStatus status) => switch (status) {
        OrderStatus.pickedUp => 'الطيار استلم الطلب من المتجر',
        OrderStatus.onTheWay => 'الطيار في الطريق إليك',
        OrderStatus.delivered => 'تم تسليم الطلب',
        OrderStatus.assigned => 'تم تعيين الطيار للطلب',
        OrderStatus.cancelled => 'تم إلغاء الطلب',
        _ => 'تحديث حالة الطلب',
      };
}
