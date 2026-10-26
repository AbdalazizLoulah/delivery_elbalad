part of 'seller_products_bloc.dart';

sealed class SellerProductsEvent extends Equatable {
  const SellerProductsEvent();

  @override
  List<Object?> get props => [];
}

final class SellerProductsStarted extends SellerProductsEvent {
  const SellerProductsStarted(this.sellerId);

  final String sellerId;

  @override
  List<Object?> get props => [sellerId];
}

final class SellerProductSaved extends SellerProductsEvent {
  const SellerProductSaved(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

final class SellerProductDeleted extends SellerProductsEvent {
  const SellerProductDeleted(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}
