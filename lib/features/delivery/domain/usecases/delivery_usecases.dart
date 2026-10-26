import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../courier_eligibility.dart';

/// جلب الطلبات الجاهزة المرتبة من الأقرب لموقع الطيار.
class GetNearbyOrdersUseCase implements UseCase<List<Order>, NearbyOrdersParams> {
  const GetNearbyOrdersUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<List<Order>>> call(NearbyOrdersParams params) async {
    final result = await _repository.availableOrders(
      lat: params.lat,
      lng: params.lng,
      radiusKm: params.radiusKm,
    );
    return result.map((orders) {
      final courier = params.courier;
      final filtered = courier == null
          ? [...orders]
          : orders
              .where((order) => CourierEligibility.canServe(
                    courier: courier,
                    order: order,
                    available: params.available,
                    lat: params.lat,
                    lng: params.lng,
                    radiusKm: params.radiusKm,
                  ))
              .toList();
      filtered.sort((a, b) =>
          _distanceFromCourier(a, params).compareTo(_distanceFromCourier(b, params)));
      return filtered;
    });
  }

  double _distanceFromCourier(Order order, NearbyOrdersParams params) => DistanceCalculator.betweenKm(
        fromLat: params.lat,
        fromLng: params.lng,
        toLat: order.storeLat ?? order.addressLat,
        toLng: order.storeLng ?? order.addressLng,
      );
}

class NearbyOrdersParams extends Equatable {
  const NearbyOrdersParams({
    required this.lat,
    required this.lng,
    this.radiusKm = AppConfig.courierSearchRadiusKm,
    this.courier,
    this.available = true,
  });

  final double lat;
  final double lng;
  final double radiusKm;

  /// لو موجود، بنطبق عليه شروط الأهلية (القرب + البلد + حالة الاتاحة).
  final AppUser? courier;
  final bool available;

  @override
  List<Object?> get props => [lat, lng, radiusKm, courier, available];
}

class GetOfferedOrdersUseCase implements UseCase<List<Order>, String> {
  const GetOfferedOrdersUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<List<Order>>> call(String courierId) => _repository.offeredOrders(courierId);
}

class GetCourierOrdersUseCase implements UseCase<List<Order>, CourierOrdersParams> {
  const GetCourierOrdersUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<List<Order>>> call(CourierOrdersParams params) =>
      _repository.courierOrders(params.courierId, onlyActive: params.onlyActive);
}

class CourierOrdersParams extends Equatable {
  const CourierOrdersParams({required this.courierId, this.onlyActive = false});

  final String courierId;
  final bool onlyActive;

  @override
  List<Object?> get props => [courierId, onlyActive];
}

class AcceptOrderUseCase implements UseCase<Order, AcceptOrderParams> {
  const AcceptOrderUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<Order>> call(AcceptOrderParams params) => _repository.acceptOrder(
        orderId: params.orderId,
        courier: params.courier,
        deliveryFee: params.deliveryFee,
        lat: params.lat,
        lng: params.lng,
      );
}

class AcceptOrderParams extends Equatable {
  const AcceptOrderParams({
    required this.orderId,
    required this.courier,
    required this.deliveryFee,
    this.lat,
    this.lng,
  });

  final String orderId;
  final AppUser courier;
  final double deliveryFee;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [orderId, courier, deliveryFee, lat, lng];
}

/// نقل الطلب للمرحلة اللي بعدها من الطيار (استلمت / في الطريق / تم التسليم).
class UpdateDeliveryStatusUseCase implements UseCase<Order, DeliveryStatusParams> {
  const UpdateDeliveryStatusUseCase(this._repository);

  final OrderStatusRepository _repository;

  @override
  Future<Result<Order>> call(DeliveryStatusParams params) => _repository.updateStatus(
        orderId: params.orderId,
        status: params.status,
        actorName: params.actorName,
        note: params.note,
        courierId: params.courierId,
        courierName: params.courierName,
        courierPhone: params.courierPhone,
        paymentStatus: params.paymentStatus,
      );
}

class DeliveryStatusParams extends Equatable {
  const DeliveryStatusParams({
    required this.orderId,
    required this.status,
    required this.actorName,
    this.note = '',
    this.courierId,
    this.courierName,
    this.courierPhone,
    this.paymentStatus,
  });

  final String orderId;
  final OrderStatus status;
  final String actorName;
  final String note;
  final String? courierId;
  final String? courierName;
  final String? courierPhone;
  final PaymentStatus? paymentStatus;

  @override
  List<Object?> get props => [orderId, status, actorName, courierId, paymentStatus];
}

/// إلغاء الطلب من الطيار — مسموح فقط لو الدفع عند الاستلام.
class CancelDeliveryOrderUseCase implements UseCase<Order, CancelDeliveryOrderParams> {
  const CancelDeliveryOrderUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<Order>> call(CancelDeliveryOrderParams params) => _repository.cancelOrder(
        orderId: params.orderId,
        actorName: params.actorName,
        note: params.note,
      );
}

class CancelDeliveryOrderParams extends Equatable {
  const CancelDeliveryOrderParams({
    required this.orderId,
    required this.actorName,
    this.note = '',
  });

  final String orderId;
  final String actorName;
  final String note;

  @override
  List<Object?> get props => [orderId, actorName, note];
}

class PushCourierLocationUseCase implements UseCase<void, PushLocationParams> {
  const PushCourierLocationUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<void>> call(PushLocationParams params) => _repository.pushLocation(
        courierId: params.courierId,
        orderId: params.orderId,
        lat: params.lat,
        lng: params.lng,
      );
}

class PushLocationParams extends Equatable {
  const PushLocationParams({
    required this.courierId,
    required this.orderId,
    required this.lat,
    required this.lng,
  });

  final String courierId;
  final String orderId;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [courierId, orderId, lat, lng];
}

class WatchCourierLocationUseCase implements StreamUseCase<CourierLocation, String> {
  const WatchCourierLocationUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Stream<Result<CourierLocation>> call(String courierId) =>
      _repository.watchCourierLocation(courierId);
}

/// تعيين أقرب طيار متاح للطلب تلقائيًا - بيظهر للطيار الأقرب قبل أي حد تاني.
class AssignNearestCourierUseCase implements UseCase<void, AssignNearestCourierParams> {
  const AssignNearestCourierUseCase({required this.couriers, required this.orders});

  final CourierOrderRepository couriers;
  final OrderRepository orders;

  @override
  Future<Result<void>> call(AssignNearestCourierParams params) async {
    final orderResult = await orders.order(params.orderId);
    if (orderResult.isFailure) {
      return Result<void>.failure(orderResult.failure!);
    }
    final order = orderResult.data!;
    final couriersResult = await couriers.availableCouriers();
    if (couriersResult.isFailure) {
      return Result<void>.failure(couriersResult.failure!);
    }

    final candidates = couriersResult.data!
        .where((courier) =>
            courier.isAvailable &&
            courier.hasLocation &&
            courier.id != params.excludeCourierId &&
            CourierEligibility.canServe(courier: courier, order: order))
        .toList();
    if (candidates.isEmpty) return const Result.success(null);

    candidates.sort((a, b) => _distance(a, order).compareTo(_distance(b, order)));

    return couriers.assignCourier(
      orderId: params.orderId,
      courierId: candidates.first.id,
      asOffer: true,
    );
  }

  double _distance(AppUser courier, Order order) => DistanceCalculator.betweenKm(
        fromLat: courier.lat!,
        fromLng: courier.lng!,
        toLat: order.storeLat ?? order.addressLat,
        toLng: order.storeLng ?? order.addressLng,
      );
}

class AssignNearestCourierParams extends Equatable {
  const AssignNearestCourierParams({required this.orderId, this.excludeCourierId});

  final String orderId;
  final String? excludeCourierId;

  @override
  List<Object?> get props => [orderId, excludeCourierId];
}

class SetAvailabilityUseCase implements UseCase<void, SetAvailabilityParams> {
  const SetAvailabilityUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<void>> call(SetAvailabilityParams params) => _repository.setAvailability(
        courierId: params.courierId,
        isAvailable: params.isAvailable,
        lat: params.lat,
        lng: params.lng,
      );
}

class SetAvailabilityParams extends Equatable {
  const SetAvailabilityParams({
    required this.courierId,
    required this.isAvailable,
    required this.lat,
    required this.lng,
  });

  final String courierId;
  final bool isAvailable;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [courierId, isAvailable, lat, lng];
}

class GetAvailableCouriersUseCase implements UseCase<List<AppUser>, NoParams> {
  const GetAvailableCouriersUseCase(this._repository);

  final CourierOrderRepository _repository;

  @override
  Future<Result<List<AppUser>>> call(NoParams params) => _repository.availableCouriers();
}
