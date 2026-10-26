part of 'order_tracking_bloc.dart';

class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.order,
    this.courierLocation,
    this.remainingDistanceKm,
    this.remainingDurationMinutes,
    this.routePoints,
    this.isLoading = false,
    this.isRating = false,
    this.ratingSubmitted = false,
    this.errorMessage,
  });

  final Order? order;
  final CourierLocation? courierLocation;

  /// المسافة المتبقية بين الطيار والعميل (بالطريق لو متاحة، وإلا خط مباشر).
  final double? remainingDistanceKm;

  /// زمن الوصول المتوقع بالدقائق (من خدمة المسارات).
  final double? remainingDurationMinutes;

  /// خط الطريق الحقيقي على الخريطة.
  final List<LatLng>? routePoints;

  final bool isLoading;
  final bool isRating;
  final bool ratingSubmitted;
  final String? errorMessage;

  bool get canRate => order?.canBeRated ?? false;

  /// هل المسافة الحالية محسوبة على الطرق الفعلية ولا خط مباشر؟
  bool get hasRoadRoute => routePoints != null && routePoints!.length > 1;

  OrderTrackingState copyWith({
    Order? order,
    CourierLocation? courierLocation,
    double? remainingDistanceKm,
    double? remainingDurationMinutes,
    List<LatLng>? routePoints,
    bool? isLoading,
    bool? isRating,
    bool? ratingSubmitted,
    String? errorMessage,
    bool clearError = false,
    bool clearRoute = false,
    bool clearDuration = false,
  }) {
    return OrderTrackingState(
      order: order ?? this.order,
      courierLocation: courierLocation ?? this.courierLocation,
      remainingDistanceKm:
          clearRoute ? null : (remainingDistanceKm ?? this.remainingDistanceKm),
      remainingDurationMinutes: clearRoute || clearDuration
          ? null
          : (remainingDurationMinutes ?? this.remainingDurationMinutes),
      routePoints: clearRoute ? null : (routePoints ?? this.routePoints),
      isLoading: isLoading ?? this.isLoading,
      isRating: isRating ?? this.isRating,
      ratingSubmitted: ratingSubmitted ?? this.ratingSubmitted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        order,
        courierLocation,
        remainingDistanceKm,
        remainingDurationMinutes,
        routePoints,
        isLoading,
        isRating,
        ratingSubmitted,
        errorMessage,
      ];
}
