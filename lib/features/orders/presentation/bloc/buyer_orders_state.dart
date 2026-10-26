part of 'buyer_orders_bloc.dart';

class BuyerOrdersState extends Equatable {
  const BuyerOrdersState({
    this.orders = const [],
    this.userId = '',
    this.isLoading = false,
    this.cancellingOrderId,
    this.errorMessage,
  });

  final List<Order> orders;
  final String userId;
  final bool isLoading;
  final String? cancellingOrderId;
  final String? errorMessage;

  List<Order> get activeOrders => orders.where((order) => order.status.isActive).toList();

  List<Order> get pastOrders => orders.where((order) => order.status.isFinal).toList();

  BuyerOrdersState copyWith({
    List<Order>? orders,
    String? userId,
    bool? isLoading,
    String? cancellingOrderId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BuyerOrdersState(
      orders: orders ?? this.orders,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      cancellingOrderId: cancellingOrderId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [orders, userId, isLoading, cancellingOrderId, errorMessage];
}
