import '../result/result.dart';

/// استخدام واحد = مسؤولية واحدة (Single Responsibility Principle).
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

abstract interface class StreamUseCase<T, P> {
  Stream<Result<T>> call(P params);
}

/// للـ use cases اللي مش محتاجة باراميترز.
class NoParams {
  const NoParams();
}

extension ResultX<T> on Future<Result<T>> {
  Future<Result<R>> mapSuccess<R>(R Function(T data) mapper) async {
    final result = await this;
    return result.map(mapper);
  }
}
