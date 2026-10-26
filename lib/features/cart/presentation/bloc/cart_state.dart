part of 'cart_bloc.dart';

class CartState extends Equatable {
  const CartState({
    this.lines = const [],
    this.userId = '',
    this.isLoading = false,
    this.errorMessage,
    this.lastAddedProductId,
  });

  final List<CartLine> lines;
  final String userId;
  final bool isLoading;
  final String? errorMessage;

  /// بيتستخدم علشان نوريه "المنتج اتضاف" في شاشة المنتج.
  final String? lastAddedProductId;

  CartSummary get summary => CartSummary.fromLines(lines);

  int get itemsCount => summary.itemsCount;

  double get subtotal => summary.subtotal;

  int quantityOf(String productId) =>
      lines.where((line) => line.product.id == productId).firstOrNull?.quantity ?? 0;

  bool contains(String productId) => quantityOf(productId) > 0;

  CartState copyWith({
    List<CartLine>? lines,
    String? userId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? lastAddedProductId,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastAddedProductId: lastAddedProductId ?? this.lastAddedProductId,
    );
  }

  @override
  List<Object?> get props => [lines, userId, isLoading, errorMessage, lastAddedProductId];
}
