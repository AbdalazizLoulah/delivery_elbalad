import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../domain/entities/cart_line.dart';

/// حفظ السلة محليًا على الجهاز (بتفضل موجودة بين الجلسات).
class CartLocalDataSource {
  CartLocalDataSource(this._preferences);

  final SharedPreferences _preferences;

  String _key(String userId) => 'cart_$userId';

  Future<List<CartLine>> load(String userId) async {
    final raw = _preferences.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((entry) {
            final map = Map<String, dynamic>.from(entry);
            final product = ProductModel.fromJson(
              Map<String, dynamic>.from(map['product'] as Map),
            );
            return CartLine(product: product, quantity: (map['quantity'] as num).toInt());
          })
          .toList();
    } catch (_) {
      throw const CacheException('مش قادرين نقرأ السلة المحفوظة.');
    }
  }

  Future<void> save(String userId, List<CartLine> lines) async {
    final payload = jsonEncode([
      for (final line in lines)
        {
          'product': ProductModel.fromEntity(line.product).toJson(includeId: true),
          'quantity': line.quantity,
        },
    ]);
    final ok = await _preferences.setString(_key(userId), payload);
    if (!ok) throw const CacheException('مش قادرين نحفظ السلة.');
  }
}

/// حفظ المفضلة محليًا (معرفات المنتجات).
class FavoritesLocalDataSource {
  FavoritesLocalDataSource(this._preferences);

  final SharedPreferences _preferences;

  String _key(String userId) => 'favorites_$userId';

  Future<List<String>> loadIds(String userId) async {
    final raw = _preferences.getStringList(_key(userId));
    return raw ?? const [];
  }

  Future<void> saveIds(String userId, List<String> productIds) async {
    final ok = await _preferences.setStringList(_key(userId), productIds);
    if (!ok) throw const CacheException('مش قادرين نحفظ المفضلة.');
  }
}
