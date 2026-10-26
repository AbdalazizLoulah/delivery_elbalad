import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;

import '../../../../core/services/route_service.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../delivery/domain/usecases/delivery_usecases.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/order_usecases.dart';

part 'order_tracking_event.dart';
part 'order_tracking_state.dart';

/// بلوك تتبع الطلب: بيسمع تحديثات الطلب والطيار (Realtime) وبيعرض الخط الزمني والخريطة،
/// وبيحسب المسافة المتبقية الحقيقية بالطريق بين الطيار والعميل.
class OrderTrackingBloc extends Bloc<OrderTrackingEvent, OrderTrackingState> {
  OrderTrackingBloc({
    required this._getOrderDetails,
    required this._watchOrder,
    required this._watchCourierLocation,
    required this._rateDelivery,
    required this._routeService,
  }) : super(const OrderTrackingState()) {
    on<OrderTrackingStarted>(_onStarted);
    on<OrderTrackingOrderReceived>(_onOrderReceived);
    on<OrderTrackingCourierMoved>(_onCourierMoved);
    on<OrderTrackingPolled>(_onPolled);
    on<OrderTrackingRouteReceived>(_onRouteReceived);
    on<OrderTrackingRateRequested>(_onRateRequested);
    on<OrderTrackingFailed>(_onFailed);
  }

  final GetOrderDetailsUseCase _getOrderDetails;
  final WatchOrderUseCase _watchOrder;
  final WatchCourierLocationUseCase _watchCourierLocation;
  final RateDeliveryUseCase _rateDelivery;
  final RouteService _routeService;

  StreamSubscription<dynamic>? _orderSubscription;
  StreamSubscription<dynamic>? _locationSubscription;

  /// تحديث دوري احتياطي (لو Realtime متأخر).
  Timer? _pollTimer;
  String? _orderId;

  /// الطيار اللي بنسمع موقعه حاليًا (لتجنب إعادة الاشتراك).
  String? _courierSubscribed;

  /// حالة طلبات حساب المسار (منع التكرار وضربات الشبكة الزيادة).
  bool _routeInFlight = false;
  int _routeGeneration = 0;
  String? _lastRouteKey;
  DateTime? _lastRouteAt;

  Future<void> _onStarted(OrderTrackingStarted event, Emitter<OrderTrackingState> emit) async {
    final isNewOrder = _orderId != event.orderId;
    _orderId = event.orderId;
    if (isNewOrder) {
      _resetRouteTracking();
      emit(state.copyWith(clearRoute: true));
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getOrderDetails(event.orderId);
    if (result.isFailure) {
      emit(state.copyWith(isLoading: false, errorMessage: result.failure!.message));
      return;
    }
    final order = result.data!;
    emit(state.copyWith(order: order, isLoading: false));
    _listenToCourier(order.courierId);

    await _orderSubscription?.cancel();
    _orderSubscription = _watchOrder(event.orderId).listen((streamResult) {
      streamResult.fold(
        (fresh) => add(OrderTrackingOrderReceived(fresh)),
        (failure) => add(OrderTrackingFailed(failure.message)),
      );
    });

    _startPolling();
  }

  /// كل 8 ثواني بنجيب الطلب وموقع الطيار من جديد — احتياطي للتتبع اللحظي.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => add(const OrderTrackingPolled()),
    );
  }

  Future<void> _onPolled(OrderTrackingPolled event, Emitter<OrderTrackingState> emit) async {
    final orderId = _orderId;
    if (orderId == null) return;

    final result = await _getOrderDetails(orderId);
    if (result.isFailure) return;
    final fresh = result.data!;
    emit(state.copyWith(order: fresh));

    final courierId = fresh.courierId;
    final courierActive = fresh.status == OrderStatus.assigned ||
        fresh.status == OrderStatus.pickedUp ||
        fresh.status == OrderStatus.onTheWay;
    if (courierId != null && courierId.isNotEmpty && courierActive) {
      // إعادة الاشتراك بترجع آخر موقع محفوظ فورًا حتى لو Realtime مش شغال.
      _listenToCourier(courierId);
    }
  }

  void _onOrderReceived(OrderTrackingOrderReceived event, Emitter<OrderTrackingState> emit) {
    emit(state.copyWith(order: event.order, clearError: true));
    if (_courierSubscribed != event.order.courierId) {
      _listenToCourier(event.order.courierId);
    }
  }

  void _onCourierMoved(OrderTrackingCourierMoved event, Emitter<OrderTrackingState> emit) {
    final order = state.order;
    final straightKm = order == null
        ? null
        : DistanceCalculator.betweenKm(
            fromLat: event.location.lat,
            fromLng: event.location.lng,
            toLat: order.addressLat,
            toLng: order.addressLng,
          );

    emit(state.copyWith(
      courierLocation: event.location,
      // لو لسه مفيش مسار طرق، نعرض الخط المباشر فورًا لحد ما المسار يوصل.
      remainingDistanceKm: state.hasRoadRoute ? null : straightKm,
    ));

    if (order != null) {
      _requestRoute(courier: event.location, order: order);
    }
  }

  void _onRouteReceived(OrderTrackingRouteReceived event, Emitter<OrderTrackingState> emit) {
    emit(state.copyWith(
      remainingDistanceKm: event.route.distanceKm,
      remainingDurationMinutes: event.route.durationMinutes,
      routePoints: event.route.points,
    ));
  }

  /// بنطلب مسار السواقة الحقيقي (OSRM) مع منع الطلبات المتكررة.
  void _requestRoute({required CourierLocation courier, required Order order}) {
    if (!order.status.isActive) return;

    final key = '${courier.lat.toStringAsFixed(4)},${courier.lng.toStringAsFixed(4)},'
        '${order.addressLat.toStringAsFixed(4)},${order.addressLng.toStringAsFixed(4)}';
    if (_routeInFlight || key == _lastRouteKey) return;

    final now = DateTime.now();
    if (_lastRouteAt != null &&
        now.difference(_lastRouteAt!) < const Duration(seconds: 6)) {
      return;
    }

    _routeInFlight = true;
    _lastRouteKey = key;
    _lastRouteAt = now;
    final generation = ++_routeGeneration;
    unawaited(_fetchRoute(courier, order, generation));
  }

  Future<void> _fetchRoute(CourierLocation courier, Order order, int generation) async {
    try {
      final route = await _routeService.drivingRoute(
        from: LatLng(courier.lat, courier.lng),
        to: LatLng(order.addressLat, order.addressLng),
      );
      if (route == null || isClosed || generation != _routeGeneration) return;
      add(OrderTrackingRouteReceived(route));
    } finally {
      if (generation == _routeGeneration) {
        _routeInFlight = false;
      }
    }
  }

  void _resetRouteTracking() {
    _routeGeneration++;
    _routeInFlight = false;
    _lastRouteKey = null;
    _lastRouteAt = null;
  }

  Future<void> _onRateRequested(
    OrderTrackingRateRequested event,
    Emitter<OrderTrackingState> emit,
  ) async {
    final order = state.order;
    final courierId = order?.courierId;
    if (order == null || courierId == null || courierId.isEmpty) return;

    emit(state.copyWith(isRating: true, clearError: true));
    final result = await _rateDelivery(RateDeliveryParams(
      orderId: order.id,
      courierId: courierId,
      rating: event.rating,
      comment: event.comment,
      buyerName: order.buyerName,
    ));
    result.fold(
      (updated) => emit(state.copyWith(isRating: false, order: updated, ratingSubmitted: true)),
      (failure) => emit(state.copyWith(isRating: false, errorMessage: failure.message)),
    );
  }

  void _onFailed(OrderTrackingFailed event, Emitter<OrderTrackingState> emit) {
    emit(state.copyWith(errorMessage: event.message));
  }

  void _listenToCourier(String? courierId) {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _courierSubscribed = courierId;
    if (courierId == null || courierId.isEmpty) return;

    _locationSubscription = _watchCourierLocation(courierId).listen((result) {
      result.fold(
        (location) => add(OrderTrackingCourierMoved(location)),
        (_) {},
      );
    });
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    _routeGeneration++;
    await _orderSubscription?.cancel();
    await _locationSubscription?.cancel();
    return super.close();
  }
}
