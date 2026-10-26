import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/address.dart';

abstract interface class ProfileRepository {
  Future<Result<AppUser>> profile(String userId);

  Future<Result<AppUser>> updateProfile(AppUser user);

  Future<Result<List<Address>>> addresses(String userId);

  Future<Result<Address>> saveAddress(Address address);

  Future<Result<void>> deleteAddress(String addressId);
}
