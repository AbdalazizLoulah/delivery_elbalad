import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cart_line.dart';
import '../repositories/cart_repository.dart';

class LoadCartUseCase implements UseCase<List<CartLine>, String> {
  const LoadCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<List<CartLine>>> call(String userId) => _repository.load(userId);
}

class SaveCartUseCase implements UseCase<void, SaveCartParams> {
  const SaveCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<void>> call(SaveCartParams params) => _repository.save(params.userId, params.lines);
}

class SaveCartParams extends Equatable {
  const SaveCartParams({required this.userId, required this.lines});

  final String userId;
  final List<CartLine> lines;

  @override
  List<Object?> get props => [userId, lines];
}
