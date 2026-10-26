part of 'catalog_bloc.dart';

sealed class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

final class CatalogStarted extends CatalogEvent {
  const CatalogStarted();
}

final class CatalogCategorySelected extends CatalogEvent {
  const CatalogCategorySelected(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

final class CatalogSearchChanged extends CatalogEvent {
  const CatalogSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
