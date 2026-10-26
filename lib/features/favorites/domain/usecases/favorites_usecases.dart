import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cart/domain/repositories/cart_repository.dart' show FavoritesRepository;

class LoadFavoritesUseCase implements UseCase<List<String>, String> {
  const LoadFavoritesUseCase(this._repository);

  final FavoritesRepository _repository;

  @override
  Future<Result<List<String>>> call(String userId) => _repository.loadIds(userId);
}

class SaveFavoritesUseCase implements UseCase<void, SaveFavoritesParams> {
  const SaveFavoritesUseCase(this._repository);

  final FavoritesRepository _repository;

  @override
  Future<Result<void>> call(SaveFavoritesParams params) =>
      _repository.saveIds(params.userId, params.productIds);
}

class SaveFavoritesParams extends Equatable {
  const SaveFavoritesParams({required this.userId, required this.productIds});

  final String userId;
  final List<String> productIds;

  @override
  List<Object?> get props => [userId, productIds];
}
