part of 'order_tracking_bloc.dart';

sealed class OrderTrackingEvent extends Equatable {
  const OrderTrackingEvent();

  @override
  List<Object?> get props => [];
}

final class OrderTrackingStarted extends OrderTrackingEvent {
  const OrderTrackingStarted(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

final class OrderTrackingOrderReceived extends OrderTrackingEvent {
  const OrderTrackingOrderReceived(this.order);

  final Order order;

  @override
  List<Object?> get props => [order];
}

final class OrderTrackingCourierMoved extends OrderTrackingEvent {
  const OrderTrackingCourierMoved(this.location);

  final CourierLocation location;

  @override
  List<Object?> get props => [location];
}

/// تحديث دوري احتياطي في حال Realtime متأخر أو مش متفعّل على المشروع.
final class OrderTrackingPolled extends OrderTrackingEvent {
  const OrderTrackingPolled();
}

/// وصل مسار السواقة الحقيقي من خدمة المسارات.
final class OrderTrackingRouteReceived extends OrderTrackingEvent {
  const OrderTrackingRouteReceived(this.route);

  final DrivingRoute route;

  @override
  List<Object?> get props => [route];
}

final class OrderTrackingRateRequested extends OrderTrackingEvent {
  const OrderTrackingRateRequested({required this.rating, this.comment = ''});

  final int rating;
  final String comment;

  @override
  List<Object?> get props => [rating, comment];
}

final class OrderTrackingFailed extends OrderTrackingEvent {
  const OrderTrackingFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
