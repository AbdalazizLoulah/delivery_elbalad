import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/usecases/order_usecases.dart';

part 'buyer_orders_event.dart';
part 'buyer_orders_state.dart';

/// بلوك طلبات المشتري (مع إمكانية الإلغاء).
class BuyerOrdersBloc extends Bloc<BuyerOrdersEvent, BuyerOrdersState> {
  BuyerOrdersBloc({
    required this._getBuyerOrders,
    required this._cancelOrder,
  }) : super(const BuyerOrdersState()) {
    on<BuyerOrdersStarted>(_onStarted);
    on<BuyerOrdersRefreshed>(_onRefreshed);
    on<BuyerOrderCancelled>(_onCancelled);
  }

  final GetBuyerOrdersUseCase _getBuyerOrders;
  final CancelOrderUseCase _cancelOrder;

  Future<void> _onStarted(BuyerOrdersStarted event, Emitter<BuyerOrdersState> emit) async {
    emit(state.copyWith(isLoading: true, userId: event.userId, clearError: true));
    final result = await _getBuyerOrders(event.userId);
    result.fold(
      (orders) => emit(state.copyWith(orders: orders, isLoading: false)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onRefreshed(BuyerOrdersRefreshed event, Emitter<BuyerOrdersState> emit) async {
    if (state.userId.isEmpty) return;
    final result = await _getBuyerOrders(state.userId);
    result.fold(
      (orders) => emit(state.copyWith(orders: orders, clearError: true)),
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
    );
  }

  Future<void> _onCancelled(BuyerOrderCancelled event, Emitter<BuyerOrdersState> emit) async {
    emit(state.copyWith(cancellingOrderId: event.order.id, clearError: true));
    final result = await _cancelOrder(
      CancelOrderParams(orderId: event.order.id, actorName: event.order.buyerName),
    );
    result.fold(
      (updated) => emit(state.copyWith(
        cancellingOrderId: null,
        orders: [
          for (final order in state.orders)
            if (order.id == updated.id) updated else order,
        ],
      )),
      (failure) => emit(state.copyWith(cancellingOrderId: null, errorMessage: failure.message)),
    );
  }
}
