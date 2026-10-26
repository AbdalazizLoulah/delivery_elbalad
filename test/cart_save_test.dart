import 'package:delivery_elbalad/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:delivery_elbalad/features/cart/domain/entities/cart_line.dart';
import 'package:delivery_elbalad/features/catalog/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('cart save works', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ds = CartLocalDataSource(prefs);
    await ds.save('u-1', const [
      CartLine(
        product: Product(
          id: 'p-test',
          sellerId: 'u-seller-1',
          title: 'منتج تجريبي',
          price: 25,
          stock: 5,
          sellerName: 'متجر تجريبي',
        ),
        quantity: 1,
      ),
    ]);
    final lines = await ds.load('u-1');
    expect(lines.length, 1);
  });
}
