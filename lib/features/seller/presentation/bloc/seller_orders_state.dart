part of 'seller_orders_bloc.dart';

class SellerOrdersState extends Equatable {
  const SellerOrdersState({
    this.orders = const [],
    this.sellerId = '',
    this.isLoading = false,
    this.updatingOrderId,
    this.lastUpdatedStatus,
    this.errorMessage,
  });

  final List<Order> orders;
  final String sellerId;
  final bool isLoading;
  final String? updatingOrderId;
  final OrderStatus? lastUpdatedStatus;
  final String? errorMessage;

  List<Order> get newOrders => orders.where((order) => order.status == OrderStatus.pendingSeller).toList();

  List<Order> get inProgress => orders
      .where((order) =>
          order.status == OrderStatus.confirmed ||
          order.status == OrderStatus.preparing ||
          order.status == OrderStatus.readyForPickup)
      .toList();

  List<Order> get finished => orders.where((order) => order.status.isFinal).toList();

  double get revenue => orders
      .where((order) => order.status == OrderStatus.delivered)
      .fold(0, (sum, order) => sum + order.itemsSubtotal);

  SellerOrdersState copyWith({
    List<Order>? orders,
    String? sellerId,
    bool? isLoading,
    String? updatingOrderId,
    OrderStatus? lastUpdatedStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerOrdersState(
      orders: orders ?? this.orders,
      sellerId: sellerId ?? this.sellerId,
      isLoading: isLoading ?? this.isLoading,
      updatingOrderId: updatingOrderId,
      lastUpdatedStatus: lastUpdatedStatus ?? this.lastUpdatedStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [orders, sellerId, isLoading, updatingOrderId, lastUpdatedStatus, errorMessage];
}
