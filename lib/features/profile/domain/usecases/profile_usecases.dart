import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/address.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase implements UseCase<AppUser, String> {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<AppUser>> call(String userId) => _repository.profile(userId);
}

class UpdateProfileUseCase implements UseCase<AppUser, AppUser> {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<AppUser>> call(AppUser user) => _repository.updateProfile(user);
}

class GetAddressesUseCase implements UseCase<List<Address>, String> {
  const GetAddressesUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<List<Address>>> call(String userId) => _repository.addresses(userId);
}

class SaveAddressUseCase implements UseCase<Address, Address> {
  const SaveAddressUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<Address>> call(Address address) => _repository.saveAddress(address);
}

class DeleteAddressUseCase implements UseCase<void, String> {
  const DeleteAddressUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<void>> call(String addressId) => _repository.deleteAddress(addressId);
}

class NewAddressParams extends Equatable {
  const NewAddressParams({required this.userId, required this.lat, required this.lng});

  final String userId;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [userId, lat, lng];
}
