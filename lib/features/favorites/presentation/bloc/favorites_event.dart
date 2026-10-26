part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

final class FavoritesStarted extends FavoritesEvent {
  const FavoritesStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class FavoriteToggled extends FavoritesEvent {
  const FavoriteToggled(this.product);

  final Product product;

  @override
  List<Object?> get props => [product.id];
}
