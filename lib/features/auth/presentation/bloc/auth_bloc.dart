import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required GetCurrentUserUseCase getCurrentUser,
    required WatchAuthStateUseCase watchAuthState,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _watchAuthState = watchAuthState,
       super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthProfileChanged>(_onProfileChanged);
  }

  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;
  final WatchAuthStateUseCase _watchAuthState;

  StreamSubscription<dynamic>? _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final user = await _getCurrentUser();

      emit(
        state.copyWith(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
          clearUser: user == null,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          clearUser: true,
          errorMessage: 'تعذر التحقق من جلسة تسجيل الدخول.',
        ),
      );
    }

    await _subscription?.cancel();

    try {
      _subscription = _watchAuthState(const NoParams()).listen(
        (result) {
          result.fold((user) => add(AuthProfileChanged(user)), (_) {});
        },
        onError: (Object error, StackTrace stackTrace) {
          addError(error, stackTrace);
        },
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }


  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await _signIn(
        SignInParams(email: event.email, password: event.password),
      );

      result.fold(
        (user) => emit(
          state.copyWith(
            isLoading: false,
            status: AuthStatus.authenticated,
            user: user,
            clearError: true,
          ),
        ),
        (failure) => emit(
          state.copyWith(
            isLoading: false,
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'حدث خطأ أثناء تسجيل الدخول.',
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await _signUp(
        SignUpParams(
          fullName: event.fullName,
          email: event.email,
          password: event.password,
          phone: event.phone,
          role: event.role,
        ),
      );

      result.fold(
        (user) => emit(
          state.copyWith(
            isLoading: false,
            status: AuthStatus.authenticated,
            user: user,
            clearError: true,
          ),
        ),
        (failure) => emit(
          state.copyWith(
            isLoading: false,
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'حدث خطأ أثناء إنشاء الحساب.',
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _signOut(const NoParams());

      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(
        state.copyWith(isLoading: false, errorMessage: 'تعذر تسجيل الخروج.'),
      );
    }
  }

void _onProfileChanged(AuthProfileChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        user: event.user,
        clearUser: event.user == null,
        status: event.user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
