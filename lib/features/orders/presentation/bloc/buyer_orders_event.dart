part of 'buyer_orders_bloc.dart';

sealed class BuyerOrdersEvent extends Equatable {
  const BuyerOrdersEvent();

  @override
  List<Object?> get props => [];
}

final class BuyerOrdersStarted extends BuyerOrdersEvent {
  const BuyerOrdersStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class BuyerOrdersRefreshed extends BuyerOrdersEvent {
  const BuyerOrdersRefreshed();
}

final class BuyerOrderCancelled extends BuyerOrdersEvent {
  const BuyerOrderCancelled(this.order);

  final Order order;

  @override
  List<Object?> get props => [order.id];
}
