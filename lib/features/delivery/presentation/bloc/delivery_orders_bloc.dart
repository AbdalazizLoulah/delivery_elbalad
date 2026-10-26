import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/courier_eligibility.dart';
import '../../domain/entities/nearby_order.dart';
import '../../domain/usecases/delivery_usecases.dart';

part 'delivery_orders_event.dart';
part 'delivery_orders_state.dart';

/// بلوك لوحة الطيار: الطلبات المعروضة عليه (الأقرب)، الطلبات المتاحة القريبة،
/// الطلبات الحالية، وبث موقعه بشكل مستمر للمشتري.
class DeliveryOrdersBloc extends Bloc<DeliveryOrdersEvent, DeliveryOrdersState> {
  DeliveryOrdersBloc({
    required this._getNearbyOrders,
    required this._getOfferedOrders,
    required this._getCourierOrders,
    required this._acceptOrder,
    required this._updateDeliveryStatus,
    required this._cancelDeliveryOrder,
    required this._pushCourierLocation,
    required this._setAvailability,
    required this._assignNearestCourier,
    required this._locationService,
  }) : super(const DeliveryOrdersState()) {
    on<DeliveryDashboardStarted>(_onStarted);
    on<DeliveryDashboardRefreshed>(_onRefreshed);
    on<DeliveryDashboardPolled>(_onPolled);
    on<DeliveryAvailabilityToggled>(_onAvailabilityToggled);
    on<DeliveryOfferAccepted>(_onOfferAccepted);
    on<DeliveryOfferDeclined>(_onOfferDeclined);
    on<DeliveryStatusAdvanced>(_onStatusAdvanced);
    on<DeliveryOrderCancelled>(_onOrderCancelled);
    on<DeliveryLocationBroadcast>(_onLocationBroadcast);
  }

  final GetNearbyOrdersUseCase _getNearbyOrders;
  final GetOfferedOrdersUseCase _getOfferedOrders;
  final GetCourierOrdersUseCase _getCourierOrders;
  final AcceptOrderUseCase _acceptOrder;
  final UpdateDeliveryStatusUseCase _updateDeliveryStatus;
  final CancelDeliveryOrderUseCase _cancelDeliveryOrder;
  final PushCourierLocationUseCase _pushCourierLocation;
  final SetAvailabilityUseCase _setAvailability;
  final AssignNearestCourierUseCase _assignNearestCourier;
  final LocationService _locationService;

  Timer? _locationTimer;

  Future<void> _onStarted(DeliveryDashboardStarted event, Emitter<DeliveryOrdersState> emit) async {
    final isAvailable = event.courier.isAvailable;
    emit(state.copyWith(
      courier: event.courier,
      isAvailable: isAvailable,
      isLoading: true,
      clearError: true,
    ));

    final location = await _resolveLocation(event.courier);
    emit(state.copyWith(myLocation: location));

    // بنحدّث الموقع بس مع الحفاظ على حالة الاتاحة الحالية للطيار.
    // (مينفعش نفعّله تلقائيًا لو هو قافل استلام الطلبات.)
    if (location != null) {
      await _setAvailability(SetAvailabilityParams(
        courierId: event.courier.id,
        isAvailable: isAvailable,
        lat: location.lat,
        lng: location.lng,
      ));
    }

    await _load(emit, isAvailable: isAvailable);
    _startLocationTimer();
  }

  Future<void> _onRefreshed(DeliveryDashboardRefreshed event, Emitter<DeliveryOrdersState> emit) async {
    final location = await _resolveLocation(state.courier);
    if (location != null) emit(state.copyWith(myLocation: location));
    await _load(emit);

    // بث مستمر للموقع طول ما فيه طلب نشط مع الطيار،
    // علشان العميل يشوف العربية بتتحرك على الخريطة لحظة بلحظة.
    final point = location ?? state.myLocation;
    final activeOrder = state.activeOrders.firstOrNull;
    if (point != null && activeOrder != null) {
      await _pushLocationPoint(activeOrder.id, point);
    }
  }

  Future<void> _onPolled(DeliveryDashboardPolled event, Emitter<DeliveryOrdersState> emit) async {
    if (state.courier == null) return;
    await _load(emit);
  }

  Future<void> _onAvailabilityToggled(
    DeliveryAvailabilityToggled event,
    Emitter<DeliveryOrdersState> emit,
  ) async {
    final courier = state.courier;
    if (courier == null) return;

    final location = state.myLocation ?? await _resolveLocation(courier);
    final lat = location?.lat ?? courier.lat;
    final lng = location?.lng ?? courier.lng;
    if (lat == null || lng == null) {
      emit(state.copyWith(
        errorMessage: 'محتاجين نحدد موقعك الأول علشان تقدر تستلم طلبات.',
      ));
      return;
    }

    emit(state.copyWith(
      courier: courier.copyWith(isAvailable: event.isAvailable),
      isAvailable: event.isAvailable,
      myLocation: location,
      offered: event.isAvailable ? state.offered : const [],
      nearby: event.isAvailable ? state.nearby : const [],
      clearError: true,
    ));

    final result = await _setAvailability(SetAvailabilityParams(
      courierId: courier.id,
      isAvailable: event.isAvailable,
      lat: lat,
      lng: lng,
    ));
    result.fold(
      (_) => emit(state.copyWith(
        successMessage: event.isAvailable ? 'أنت متاح لاستلام طلبات جديدة' : 'توقفت عن استلام الطلبات',
      )),
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
    );

    await _load(emit);
  }

  Future<void> _onOfferAccepted(DeliveryOfferAccepted event, Emitter<DeliveryOrdersState> emit) async {
    final courier = state.courier;
    if (courier == null) return;

    if (!state.isAvailable) {
      emit(state.copyWith(
        errorMessage: 'فعّل حالة "متاح" الأول علشان تقدر تستلم طلبات.',
      ));
      return;
    }

    final location = state.myLocation;
    final eligible = CourierEligibility.canServe(
      courier: courier,
      order: event.order,
      available: true,
      lat: location?.lat,
      lng: location?.lng,
    );
    if (!eligible) {
      emit(state.copyWith(
        errorMessage: 'الطلب مش متاح ليك: بعيد عن المتجر أو خارج نطاق بلدك.',
      ));
      add(const DeliveryDashboardRefreshed());
      return;
    }

    emit(state.copyWith(updatingOrderId: event.order.id, clearError: true));
    final result = await _acceptOrder(AcceptOrderParams(
      orderId: event.order.id,
      courier: courier,
      deliveryFee: event.order.deliveryFee,
      lat: location?.lat,
      lng: location?.lng,
    ));

    result.fold(
      (order) {
        emit(state.copyWith(
          updatingOrderId: null,
          successMessage: 'تم قبول الطلب ${order.code}',
          lastAcceptedOrder: order,
        ));
        add(const DeliveryDashboardRefreshed());
      },
      (failure) => emit(state.copyWith(updatingOrderId: null, errorMessage: failure.message)),
    );
  }

  Future<void> _onOfferDeclined(DeliveryOfferDeclined event, Emitter<DeliveryOrdersState> emit) async {
    final courier = state.courier;
    if (courier == null) return;

    emit(state.copyWith(updatingOrderId: event.order.id, clearError: true));
    // بنشيل العرض عن الطيار دا وبنعرضه على الطيار الأقرب بعده.
    await _assignNearestCourier(AssignNearestCourierParams(
      orderId: event.order.id,
      excludeCourierId: courier.id,
    ));
    emit(state.copyWith(
      updatingOrderId: null,
      offered: state.offered.where((order) => order.id != event.order.id).toList(),
      successMessage: 'تم تجاهل الطلب وعرضه على طيار تاني',
    ));
    add(const DeliveryDashboardRefreshed());
  }

  Future<void> _onStatusAdvanced(DeliveryStatusAdvanced event, Emitter<DeliveryOrdersState> emit) async {
    final next = event.order.nextCourierStatus;
    if (next == null) return;
    final courier = state.courier;

    emit(state.copyWith(updatingOrderId: event.order.id, clearError: true));

    if (next == OrderStatus.pickedUp) {
      await _broadcastLocation(event.order.id);
    }

    final result = await _updateDeliveryStatus(DeliveryStatusParams(
      orderId: event.order.id,
      status: next,
      actorName: courier?.fullName ?? 'الطيار',
      courierId: courier?.id,
      courierName: courier?.fullName,
      courierPhone: courier?.phone,
    ));

    result.fold(
      (order) {
        emit(state.copyWith(
          updatingOrderId: null,
          lastAdvancedOrder: order,
          successMessage: _statusMessage(next),
        ));
        add(const DeliveryDashboardRefreshed());
      },
      (failure) => emit(state.copyWith(updatingOrderId: null, errorMessage: failure.message)),
    );
  }

  Future<void> _onOrderCancelled(DeliveryOrderCancelled event, Emitter<DeliveryOrdersState> emit) async {
    final courier = state.courier;
    if (courier == null) return;

    emit(state.copyWith(updatingOrderId: event.order.id, clearError: true));
    final result = await _cancelDeliveryOrder(CancelDeliveryOrderParams(
      orderId: event.order.id,
      actorName: courier.fullName,
    ));

    result.fold(
      (order) {
        emit(state.copyWith(
          updatingOrderId: null,
          successMessage: 'تم إلغاء الطلب ${order.code}',
        ));
        add(const DeliveryDashboardRefreshed());
      },
      (failure) => emit(state.copyWith(updatingOrderId: null, errorMessage: failure.message)),
    );
  }

  Future<void> _onLocationBroadcast(
    DeliveryLocationBroadcast event,
    Emitter<DeliveryOrdersState> emit,
  ) async {
    final order = state.activeOrders.firstOrNull;
    if (order == null) return;
    await _broadcastLocation(order.id);
    emit(state.copyWith(myLocation: GeoPoint(lat: event.lat, lng: event.lng)));
  }

  Future<void> _load(Emitter<DeliveryOrdersState> emit, {bool? isAvailable}) async {
    final courier = state.courier;
    if (courier == null) return;

    final available = isAvailable ?? state.isAvailable;
    final location = state.myLocation ?? GeoPoint(lat: courier.lat ?? 0, lng: courier.lng ?? 0);

    final myOrdersResult = await _getCourierOrders(CourierOrdersParams(courierId: courier.id));
    final myOrdersFailure = myOrdersResult.failure;
    if (myOrdersFailure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: myOrdersFailure.message));
      return;
    }
    final myOrders = myOrdersResult.data ?? const <Order>[];

    // لو الطيار موقف استلام، مفيش طلبات جديدة تتعرض عليه خالص.
    if (!available) {
      emit(state.copyWith(
        isLoading: false,
        isAvailable: false,
        offered: const [],
        nearby: const [],
        myOrders: myOrders,
        clearError: true,
      ));
      return;
    }

    final offeredResult = await _getOfferedOrders(courier.id);
    final nearbyResult = await _getNearbyOrders(NearbyOrdersParams(
      lat: location.lat,
      lng: location.lng,
      radiusKm: AppConfig.courierSearchRadiusKm,
      courier: courier,
      available: available,
    ));

    final failure = offeredResult.failure ?? nearbyResult.failure;
    if (failure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      return;
    }

    final offered = (offeredResult.data ?? const <Order>[])
        .where((order) => CourierEligibility.canServe(
              courier: courier,
              order: order,
              available: available,
              lat: location.lat,
              lng: location.lng,
            ))
        .toList();

    final nearby = (nearbyResult.data ?? const <Order>[])
        .where((order) => CourierEligibility.canServe(
              courier: courier,
              order: order,
              available: available,
              lat: location.lat,
              lng: location.lng,
            ))
        .map((order) => NearbyOrder(
              order: order,
              distanceFromCourierKm: DistanceCalculator.betweenKm(
                fromLat: location.lat,
                fromLng: location.lng,
                toLat: order.storeLat ?? order.addressLat,
                toLng: order.storeLng ?? order.addressLng,
              ),
            ))
        .toList();

    emit(state.copyWith(
      isLoading: false,
      offered: offered,
      nearby: nearby,
      myOrders: myOrders,
      isAvailable: available,
      clearError: true,
    ));
  }

  Future<GeoPoint?> _resolveLocation(AppUser? courier) async {
    try {
      return await _locationService.currentPosition();
    } catch (_) {
      if (courier?.hasLocation ?? false) {
        return GeoPoint(lat: courier!.lat!, lng: courier.lng!);
      }
      return null;
    }
  }

  Future<void> _broadcastLocation(String orderId) async {
    final courier = state.courier;
    if (courier == null) return;
    try {
      final point = await _locationService.currentPosition();
      await _pushLocationPoint(orderId, point);
    } catch (_) {
      // لو الموقع مش متاح بنكمل من غير تحديث.
    }
  }

  /// بتبعت إحداثيات معروفة مسبقًا لجدول `courier_locations` بدون قراءة GPS تاني.
  Future<void> _pushLocationPoint(String orderId, GeoPoint point) async {
    final courier = state.courier;
    if (courier == null) return;
    try {
      await _pushCourierLocation(PushLocationParams(
        courierId: courier.id,
        orderId: orderId,
        lat: point.lat,
        lng: point.lng,
      ));
    } catch (_) {
      // لو الشبكة قطعت بنكمل.
    }
  }

  void _startLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // تحديث تلقائي مستمر: الطلبات الجديدة تظهر من غير ما الطيار يعمل Refresh يدوي.
      if (state.activeOrders.isNotEmpty) {
        add(const DeliveryDashboardRefreshed());
      } else {
        add(const DeliveryDashboardPolled());
      }
    });
  }

  String _statusMessage(OrderStatus status) => switch (status) {
        OrderStatus.pickedUp => 'سجلت استلام الطلب من المتجر',
        OrderStatus.onTheWay => 'الطلب في الطريق للعميل',
        OrderStatus.delivered => 'تم تسليم الطلب بنجاح 🎉',
        _ => 'تم تحديث حالة الطلب',
      };

  @override
  Future<void> close() {
    _locationTimer?.cancel();
    return super.close();
  }
}
