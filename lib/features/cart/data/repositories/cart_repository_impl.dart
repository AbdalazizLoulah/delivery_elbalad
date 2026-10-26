import '../../../../core/error/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';

/// السلة محفوظة محليًا (Offline-first) وبتترفع للباك إند مع إنشاء الطلب.
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._local);

  final CartLocalDataSource _local;

  @override
  Future<Result<List<CartLine>>> load(String userId) => guard(() => _local.load(userId));

  @override
  Future<Result<void>> save(String userId, List<CartLine> lines) =>
      guard(() => _local.save(userId, lines));
}

/// المفضلة محفوظة محليًا لكل مستخدم.
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._local);

  final FavoritesLocalDataSource _local;

  @override
  Future<Result<List<String>>> loadIds(String userId) => guard(() => _local.loadIds(userId));

  @override
  Future<Result<void>> saveIds(String userId, List<String> productIds) =>
      guard(() => _local.saveIds(userId, productIds));
}
