import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// نتيجة عملية: إما `data` أو `failure` (مش الاتنين).
class Result<T> extends Equatable {
  const Result.success(this.data) : failure = null;
  const Result.failure(this.failure) : data = null;

  final T? data;
  final AppFailure? failure;

  /// النتيجة ناجحة حتى لو القيمة `null` (مثال: `Result<void>` بعد حفظ ناجح).
  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  R fold<R>(R Function(T data) onSuccess, R Function(AppFailure failure) onFailure) {
    if (isSuccess) return onSuccess(data as T);
    return onFailure(failure ?? AppFailure.unexpected);
  }

  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess) return Result<R>.success(mapper(data as T));
    return Result<R>.failure(failure ?? AppFailure.unexpected);
  }

  @override
  List<Object?> get props => [data, failure];
}
