part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.user,
    this.profile,
    this.addresses = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.saved = false,
    this.errorMessage,
  });

  /// بيانات الجلسة الحالية (من الـ AuthBloc).
  final AppUser? user;

  /// البيانات الكاملة من قاعدة البيانات.
  final AppUser? profile;
  final List<Address> addresses;
  final bool isLoading;
  final bool isSaving;
  final bool saved;
  final String? errorMessage;

  AppUser? get displayUser => profile ?? user;

  ProfileState copyWith({
    AppUser? user,
    AppUser? profile,
    List<Address>? addresses,
    bool? isLoading,
    bool? isSaving,
    bool? saved,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      saved: saved ?? this.saved,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [user, profile, addresses, isLoading, isSaving, saved, errorMessage];
}
