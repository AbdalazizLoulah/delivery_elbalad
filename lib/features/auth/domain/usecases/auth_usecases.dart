import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase implements UseCase<AppUser, SignInParams> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AppUser>> call(SignInParams params) => _repository.signIn(
        email: params.email,
        password: params.password,
      );
}

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignUpUseCase implements UseCase<AppUser, SignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AppUser>> call(SignUpParams params) => _repository.signUp(
        fullName: params.fullName,
        email: params.email,
        password: params.password,
        phone: params.phone,
        role: params.role,
      );
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
  });

  final String fullName;
  final String email;
  final String password;
  final String phone;
  final UserRole role;

  @override
  List<Object?> get props => [fullName, email, password, phone, role];
}

class SignOutUseCase implements UseCase<void, NoParams> {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.signOut();
}

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call() => _repository.currentUser();
}

class WatchAuthStateUseCase implements StreamUseCase<AppUser?, NoParams> {
  const WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Stream<Result<AppUser?>> call(NoParams params) =>
      _repository.authStateChanges().map(Result<AppUser?>.success);
}
