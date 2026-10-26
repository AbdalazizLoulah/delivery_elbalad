part of 'seller_orders_bloc.dart';

sealed class SellerOrdersEvent extends Equatable {
  const SellerOrdersEvent();

  @override
  List<Object?> get props => [];
}

final class SellerOrdersStarted extends SellerOrdersEvent {
  const SellerOrdersStarted(this.sellerId);

  final String sellerId;

  @override
  List<Object?> get props => [sellerId];
}

final class SellerOrdersRefreshed extends SellerOrdersEvent {
  const SellerOrdersRefreshed();
}

final class SellerOrderAdvanced extends SellerOrdersEvent {
  const SellerOrderAdvanced(this.order);

  final Order order;

  @override
  List<Object?> get props => [order.id, order.status];
}

final class SellerOrderCancelled extends SellerOrdersEvent {
  const SellerOrderCancelled(this.order);

  final Order order;

  @override
  List<Object?> get props => [order.id];
}
