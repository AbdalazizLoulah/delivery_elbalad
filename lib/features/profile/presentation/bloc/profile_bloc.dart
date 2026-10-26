import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/profile_usecases.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// بلوك بروفايل المستخدم (بائع / مشتري / طيار): قراءة وتعديل البيانات.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this._getProfile,
    required this._updateProfile,
    required this._getAddresses,
  }) : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileSaved>(_onSaved);
  }

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final GetAddressesUseCase _getAddresses;

  Future<void> _onStarted(ProfileStarted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(user: event.user, isLoading: true, clearError: true));

    final profileResult = await _getProfile(event.user.id);
    final addressesResult = await _getAddresses(event.user.id);

    profileResult.fold(
      (profile) => emit(state.copyWith(
        profile: profile,
        isLoading: false,
        addresses: addressesResult.data ?? const [],
      )),
      (failure) => emit(state.copyWith(
        isLoading: false,
        profile: event.user,
        errorMessage: failure.message,
      )),
    );
  }

  Future<void> _onSaved(ProfileSaved event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _updateProfile(event.user);
    result.fold(
      (profile) => emit(state.copyWith(profile: profile, isSaving: false, saved: true)),
      (failure) => emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
    );
  }
}
