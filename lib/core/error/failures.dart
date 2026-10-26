import 'package:equatable/equatable.dart';

/// وصف الفشل اللي بيوصل لطبقة العرض (presentation).
class AppFailure extends Equatable {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;

  static const AppFailure unexpected = AppFailure('حصل خطأ غير متوقع، حاول تاني.');
  static const AppFailure network = AppFailure('فيه مشكلة في الاتصال بالإنترنت.');
  static const AppFailure notFound = AppFailure('مش قادر نلاقي البيانات المطلوبة.');

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'AppFailure($code): $message';
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message) : super(code: 'validation');
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message) : super(code: 'auth');
}

class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message) : super(code: 'permission');
}
