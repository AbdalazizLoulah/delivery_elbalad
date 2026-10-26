part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
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

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthProfileChanged extends AuthEvent {
  const AuthProfileChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}
