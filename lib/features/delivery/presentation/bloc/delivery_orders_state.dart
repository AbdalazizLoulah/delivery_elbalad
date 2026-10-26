part of 'delivery_orders_bloc.dart';

class DeliveryOrdersState extends Equatable {
  const DeliveryOrdersState({
    this.courier,
    this.myLocation,
    this.offered = const [],
    this.nearby = const [],
    this.myOrders = const [],
    this.isAvailable = true,
    this.isLoading = false,
    this.updatingOrderId,
    this.lastAcceptedOrder,
    this.lastAdvancedOrder,
    this.successMessage,
    this.errorMessage,
  });

  final AppUser? courier;
  final GeoPoint? myLocation;

  /// طلبات معروضة عليّ (أنا الأقرب للمتجر).
  final List<Order> offered;

  /// طلبات جاهزة قريبة مني (بالمسافة).
  final List<NearbyOrder> nearby;

  final List<Order> myOrders;
  final bool isAvailable;
  final bool isLoading;
  final String? updatingOrderId;
  final Order? lastAcceptedOrder;
  final Order? lastAdvancedOrder;
  final String? successMessage;
  final String? errorMessage;

  List<Order> get activeOrders => myOrders.where((order) => order.status.isActive).toList();

  List<Order> get completedOrders => myOrders
      .where((order) => order.status == OrderStatus.delivered)
      .toList(growable: false);

  double get todayEarnings => completedOrders
      .where((order) =>
          order.deliveredAt != null &&
          DateTime.now().difference(order.deliveredAt!).inHours < 24)
      .fold(0, (sum, order) => sum + order.deliveryFee);

  double get totalEarnings =>
      completedOrders.fold(0, (sum, order) => sum + order.deliveryFee);

  DeliveryOrdersState copyWith({
    AppUser? courier,
    GeoPoint? myLocation,
    List<Order>? offered,
    List<NearbyOrder>? nearby,
    List<Order>? myOrders,
    bool? isAvailable,
    bool? isLoading,
    String? updatingOrderId,
    Order? lastAcceptedOrder,
    Order? lastAdvancedOrder,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
    bool clearError = false,
  }) {
    return DeliveryOrdersState(
      courier: courier ?? this.courier,
      myLocation: myLocation ?? this.myLocation,
      offered: offered ?? this.offered,
      nearby: nearby ?? this.nearby,
      myOrders: myOrders ?? this.myOrders,
      isAvailable: isAvailable ?? this.isAvailable,
      isLoading: isLoading ?? this.isLoading,
      updatingOrderId: updatingOrderId,
      lastAcceptedOrder: lastAcceptedOrder ?? this.lastAcceptedOrder,
      lastAdvancedOrder: lastAdvancedOrder ?? this.lastAdvancedOrder,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: (clearMessages || clearError) ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        courier,
        myLocation,
        offered,
        nearby,
        myOrders,
        isAvailable,
        isLoading,
        updatingOrderId,
        lastAcceptedOrder,
        lastAdvancedOrder,
        successMessage,
        errorMessage,
      ];
}
