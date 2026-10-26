import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../delivery/domain/usecases/delivery_usecases.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/usecases/order_usecases.dart';

part 'seller_orders_event.dart';
part 'seller_orders_state.dart';

/// بلوك طلبات البائع: بيستقبل الطلب وبيحركه في المراحل، ولما يبقى جاهز
/// بيتم تعيين أقرب طيار متاح عليه تلقائيًا (Offered to nearest courier).
class SellerOrdersBloc extends Bloc<SellerOrdersEvent, SellerOrdersState> {
  SellerOrdersBloc({
    required this._getSellerOrders,
    required this._updateOrderStatus,
    required this._assignNearestCourier,
  }) : super(const SellerOrdersState()) {
    on<SellerOrdersStarted>(_onStarted);
    on<SellerOrdersRefreshed>(_onRefreshed);
    on<SellerOrderAdvanced>(_onAdvanced);
    on<SellerOrderCancelled>(_onCancelled);
  }

  final GetSellerOrdersUseCase _getSellerOrders;
  final UpdateOrderStatusUseCase _updateOrderStatus;
  final AssignNearestCourierUseCase _assignNearestCourier;

  Timer? _refreshTimer;

  /// تحديث تلقائي كل 20 ثانية عشان الطلبات الجديدة تظهر للتاجر
  /// من غير ما يعمل Refresh يدوي.
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (state.sellerId.isNotEmpty && state.updatingOrderId == null) {
        add(const SellerOrdersRefreshed());
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onStarted(SellerOrdersStarted event, Emitter<SellerOrdersState> emit) async {
    emit(state.copyWith(isLoading: true, sellerId: event.sellerId, clearError: true));
    final result = await _getSellerOrders(event.sellerId);
    result.fold(
      (orders) => emit(state.copyWith(orders: orders, isLoading: false)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
    _startAutoRefresh();
  }

  Future<void> _onRefreshed(SellerOrdersRefreshed event, Emitter<SellerOrdersState> emit) async {
    if (state.sellerId.isEmpty) return;
    final result = await _getSellerOrders(state.sellerId);
    result.fold(
      (orders) => emit(state.copyWith(orders: orders, clearError: true)),
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
    );
  }

  Future<void> _onAdvanced(SellerOrderAdvanced event, Emitter<SellerOrdersState> emit) async {
    final next = event.order.nextSellerStatus;
    if (next == null) return;

    emit(state.copyWith(updatingOrderId: event.order.id, clearError: true));
    final result = await _updateOrderStatus(UpdateOrderStatusParams(
      orderId: event.order.id,
      status: next,
      actorName: event.order.sellerName,
    ));

    if (result.isFailure) {
      emit(state.copyWith(updatingOrderId: null, errorMessage: result.failure!.message));
      return;
    }

    final updated = result.data!;
    _replace(updated, emit);
    emit(state.copyWith(updatingOrderId: null, lastUpdatedStatus: next));

    // الطلب جاهز => بنعرضه على أقرب طيار.
    if (next == OrderStatus.readyForPickup) {
      await _assignNearestCourier(AssignNearestCourierParams(orderId: updated.id));
      add(SellerOrdersRefreshed());
    }
  }

  Future<void> _onCancelled(SellerOrderCancelled event, Emitter<SellerOrdersState> emit) async {
    emit(state.copyWith(updatingOrderId: event.order.id, clearError: true));
    final result = await _updateOrderStatus(UpdateOrderStatusParams(
      orderId: event.order.id,
      status: OrderStatus.cancelled,
      actorName: event.order.sellerName,
      note: 'المتجر ألغى الطلب',
    ));
    result.fold(
      (updated) {
        emit(state.copyWith(updatingOrderId: null, lastUpdatedStatus: OrderStatus.cancelled));
        _replace(updated, emit);
      },
      (failure) => emit(state.copyWith(updatingOrderId: null, errorMessage: failure.message)),
    );
  }

  void _replace(Order updated, Emitter<SellerOrdersState> emit) {
    emit(state.copyWith(
      orders: [
        for (final order in state.orders)
          if (order.id == updated.id) updated else order,
      ],
    ));
  }
}
