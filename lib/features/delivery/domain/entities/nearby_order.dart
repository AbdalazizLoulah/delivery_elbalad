import 'package:equatable/equatable.dart';

import '../../../orders/domain/entities/order.dart';

/// طلب متاح للطيار + المسافة من موقعه الحالي.
class NearbyOrder extends Equatable {
  const NearbyOrder({required this.order, required this.distanceFromCourierKm});

  final Order order;
  final double distanceFromCourierKm;

  double get tripDistanceKm => order.distanceKm;

  NearbyOrder copyWith({Order? order, double? distanceFromCourierKm}) => NearbyOrder(
        order: order ?? this.order,
        distanceFromCourierKm: distanceFromCourierKm ?? this.distanceFromCourierKm,
      );

  @override
  List<Object?> get props => [order.id, order.status, distanceFromCourierKm];
}
