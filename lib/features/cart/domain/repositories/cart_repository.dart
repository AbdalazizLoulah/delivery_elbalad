import '../../../../core/result/result.dart';
import '../entities/cart_line.dart';

abstract interface class CartRepository {
  Future<Result<List<CartLine>>> load(String userId);

  Future<Result<void>> save(String userId, List<CartLine> lines);
}

abstract interface class FavoritesRepository {
  Future<Result<List<String>>> loadIds(String userId);

  Future<Result<void>> saveIds(String userId, List<String> productIds);
}

/// عمليات السلة كدوال نقية (Domain Logic) - سهلة الاختبار ومن غير أي اعتماديات.
class CartOperations {
  const CartOperations._();

  static List<CartLine> addOrIncrement(List<CartLine> lines, CartLine line) {
    final index = lines.indexWhere((item) => item.product.id == line.product.id);
    if (index == -1) return [...lines, line];
    final existing = lines[index];
    final updated = existing.copyWith(quantity: existing.quantity + line.quantity);
    final result = [...lines];
    result[index] = updated;
    return result;
  }

  static List<CartLine> changeQuantity(List<CartLine> lines, String productId, int quantity) {
    if (quantity <= 0) return remove(lines, productId);
    return [
      for (final line in lines)
        if (line.product.id == productId) line.copyWith(quantity: quantity) else line,
    ];
  }

  static List<CartLine> remove(List<CartLine> lines, String productId) =>
      lines.where((line) => line.product.id != productId).toList();

  static List<CartLine> removeBySeller(List<CartLine> lines, String sellerId) =>
      lines.where((line) => line.product.sellerId != sellerId).toList();
}
