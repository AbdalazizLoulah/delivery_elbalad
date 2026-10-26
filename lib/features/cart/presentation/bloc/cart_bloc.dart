import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/usecases/cart_usecases.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// بلوك السلة: بيحتفظ بالسلة في الذاكرة وبيحفظها على الجهاز مع كل تغيير.
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required this._loadCart,
    required this._saveCart,
  }) : super(const CartState()) {
    on<CartStarted>(_onStarted);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartCleared>(_onCleared);
    on<_CartPersistFailed>(_onPersistFailed);
  }

  final LoadCartUseCase _loadCart;
  final SaveCartUseCase _saveCart;

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    if (event.userId.isEmpty) {
      emit(state.copyWith(lines: const [], userId: '', isLoading: false));
      return;
    }
    emit(state.copyWith(isLoading: true, userId: event.userId, clearError: true));
    final result = await _loadCart(event.userId);
    result.fold(
      (lines) => emit(state.copyWith(lines: lines, isLoading: false)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    if (!event.product.inStock) {
      emit(state.copyWith(errorMessage: 'المنتج دا خلص من المخزن حاليًا.'));
      return;
    }
    final existing = state.lines.where((line) => line.product.id == event.product.id).firstOrNull;
    final newQuantity = (existing?.quantity ?? 0) + event.quantity;
    if (newQuantity > event.product.stock) {
      emit(state.copyWith(errorMessage: 'المتاح من المنتج دا ${event.product.stock} بس.'));
      return;
    }

    final lines = CartOperations.addOrIncrement(
      state.lines,
      CartLine(product: event.product, quantity: event.quantity),
    );
    emit(state.copyWith(lines: lines, clearError: true, lastAddedProductId: event.product.id));
    await _persist(lines);
  }

  Future<void> _onQuantityChanged(CartQuantityChanged event, Emitter<CartState> emit) async {
    final lines = CartOperations.changeQuantity(state.lines, event.productId, event.quantity);
    emit(state.copyWith(lines: lines, clearError: true));
    await _persist(lines);
  }

  Future<void> _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    final lines = CartOperations.remove(state.lines, event.productId);
    emit(state.copyWith(lines: lines, clearError: true));
    await _persist(lines);
  }

  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    final lines = event.sellerId == null
        ? <CartLine>[]
        : CartOperations.removeBySeller(state.lines, event.sellerId!);
    emit(state.copyWith(lines: lines, clearError: true));
    await _persist(lines);
  }

  Future<void> _persist(List<CartLine> lines) async {
    if (state.userId.isEmpty) return;
    final result = await _saveCart(SaveCartParams(userId: state.userId, lines: lines));
    result.fold((_) {}, (failure) => add(_CartPersistFailed(failure.message)));
  }

  /// حفظ السلة على الجهاز ممكن يفشل (مساحة ممتلئة / مشكلة في التخزين).
  /// لازم نستقبل الحدث هنا ونعرض الخطأ بهدوء بدل ما التطبيق يقع.
  void _onPersistFailed(_CartPersistFailed event, Emitter<CartState> emit) {
    emit(state.copyWith(errorMessage: event.message));
  }
}
