part of 'cart_bloc.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

final class CartStarted extends CartEvent {
  const CartStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class CartItemAdded extends CartEvent {
  const CartItemAdded({required this.product, this.quantity = 1});

  final Product product;
  final int quantity;

  @override
  List<Object?> get props => [product.id, quantity];
}

final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

final class CartQuantityChanged extends CartEvent {
  const CartQuantityChanged({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

/// إفراغ السلة كلها، أو منتجات بائع معين بعد إتمام الطلب.
final class CartCleared extends CartEvent {
  const CartCleared({this.sellerId});

  final String? sellerId;

  @override
  List<Object?> get props => [sellerId];
}

final class _CartPersistFailed extends CartEvent {
  const _CartPersistFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
