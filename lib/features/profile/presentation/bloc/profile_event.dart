part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileStarted extends ProfileEvent {
  const ProfileStarted(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user.id];
}

final class ProfileSaved extends ProfileEvent {
  const ProfileSaved(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}
