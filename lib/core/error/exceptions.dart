import 'failures.dart';

/// استثناءات طبقة البيانات (data layer).
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  AppFailure toFailure() => AppFailure(message, code: code);

  @override
  String toString() => 'AppException($code): $message';
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'في مشكلة في الاتصال بالإنترنت.'])
      : super(code: 'network');
}

class CacheException extends AppException {
  const CacheException(super.message) : super(code: 'cache');
}

class AuthException extends AppException {
  const AuthException(super.message) : super(code: 'auth');
}

class NotFoundException extends AppException {
  const NotFoundException(super.message) : super(code: 'not_found');
}
