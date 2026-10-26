part of 'delivery_orders_bloc.dart';

sealed class DeliveryOrdersEvent extends Equatable {
  const DeliveryOrdersEvent();

  @override
  List<Object?> get props => [];
}

final class DeliveryDashboardStarted extends DeliveryOrdersEvent {
  const DeliveryDashboardStarted(this.courier);

  final AppUser courier;

  @override
  List<Object?> get props => [courier.id];
}

final class DeliveryDashboardRefreshed extends DeliveryOrdersEvent {
  const DeliveryDashboardRefreshed();
}

/// تحديث هادئ للبيانات (بدون طلب GPS) — بيشتغل تلقائيًا كل فترة
/// علشان الطلبات الجديدة تظهر للطيار من غير ما يعمل Refresh يدوي.
final class DeliveryDashboardPolled extends DeliveryOrdersEvent {
  const DeliveryDashboardPolled();
}

final class DeliveryAvailabilityToggled extends DeliveryOrdersEvent {
  const DeliveryAvailabilityToggled(this.isAvailable);

  final bool isAvailable;

  @override
  List<Object?> get props => [isAvailable];
}

final class DeliveryOfferAccepted extends DeliveryOrdersEvent {
  const DeliveryOfferAccepted(this.order);

  final Order order;

  @override
  List<Object?> get props => [order.id];
}

/// رفض العرض => بيتعرض على أقرب طيار بعده.
final class DeliveryOfferDeclined extends DeliveryOrdersEvent {
  const DeliveryOfferDeclined(this.order);

  final Order order;

  @override
  List<Object?> get props => [order.id];
}

final class DeliveryStatusAdvanced extends DeliveryOrdersEvent {
  const DeliveryStatusAdvanced(this.order);

  final Order order;

  @override
  List<Object?> get props => [order.id, order.status];
}

/// إلغاء الطلب من الطيار — مسموح فقط للطلبات "الدفع عند الاستلام".
final class DeliveryOrderCancelled extends DeliveryOrdersEvent {
  const DeliveryOrderCancelled(this.order);

  final Order order;

  @override
  List<Object?> get props => [order.id];
}

final class DeliveryLocationBroadcast extends DeliveryOrdersEvent {
  const DeliveryLocationBroadcast({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}
