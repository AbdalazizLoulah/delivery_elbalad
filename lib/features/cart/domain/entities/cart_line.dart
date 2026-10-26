import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';

/// سطر في سلة المشتريات.
class CartLine extends Equatable {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get total => product.price * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);

  bool get isValidQuantity => quantity > 0 && quantity <= product.stock;

  @override
  List<Object?> get props => [product.id, quantity, product.price];
}

/// ملخص السلة (كل الحسابات في مكان واحد بدل ما تتكرر في الـ UI).
class CartSummary extends Equatable {
  const CartSummary({
    required this.lines,
    required this.itemsCount,
    required this.subtotal,
    required this.deliveryFee,
  });

  const CartSummary.empty()
      : lines = const [],
        itemsCount = 0,
        subtotal = 0,
        deliveryFee = 0;

  final List<CartLine> lines;
  final int itemsCount;
  final double subtotal;
  final double deliveryFee;

  double get total => subtotal + deliveryFee;

  bool get isEmpty => lines.isEmpty;

  /// تجميع السلة حسب البائع: كل بائع بيستلم طلب مستقل.
  Map<String, List<CartLine>> get bySeller {
    final map = <String, List<CartLine>>{};
    for (final line in lines) {
      map.putIfAbsent(line.product.sellerId, () => []).add(line);
    }
    return map;
  }

  static CartSummary fromLines(List<CartLine> lines, {double deliveryFee = 0}) {
    return CartSummary(
      lines: List.unmodifiable(lines),
      itemsCount: lines.fold(0, (sum, line) => sum + line.quantity),
      subtotal: lines.fold(0, (sum, line) => sum + line.total),
      deliveryFee: deliveryFee,
    );
  }

  @override
  List<Object?> get props => [lines, itemsCount, subtotal, deliveryFee];
}
