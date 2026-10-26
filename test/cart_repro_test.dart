// اختبار مؤقت لإعادة إنتاج مشكلة فتح تاب السلة مباشرة بعد تسجيل الدخول.
import 'package:delivery_elbalad/core/config/app_config.dart';
import 'package:delivery_elbalad/core/demo/demo_database.dart';
import 'package:delivery_elbalad/core/di/injector.dart';
import 'package:delivery_elbalad/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:delivery_elbalad/features/catalog/domain/entities/product.dart';
import 'package:delivery_elbalad/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void mockLocationChannels() {
  const channels = [
    MethodChannel('flutter.baseflow.com/geolocator'),
    MethodChannel('flutter.baseflow.com/geocoding'),
  ];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in channels) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException('no plugin in test');
    });
  }
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 60,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (tester.any(finder)) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('not found: $finder');
}

Finder navItem(String label) => find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('فتح السلة فيها منتج لا يكسر التطبيق', (tester) async {
    mockLocationChannels();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ar');
    final preferences = await SharedPreferences.getInstance();
    AppConfig.forceDemoMode(true);
    await configureDependencies(preferences, startDemoSimulation: false);

    await tester.pumpWidget(const DeliveryElBaladApp());
    await pumpUntilFound(tester, find.text('اختار نوع حسابك وابدأ حالًا'));

    await tapVisible(tester, find.text('تسجيل الدخول'));
    await pumpUntilFound(tester, find.widgetWithText(ActionChip, 'مشتري'));
    await tapVisible(tester, find.widgetWithText(ActionChip, 'مشتري'));
    await tapVisible(tester, find.text('دخول'));
    await pumpUntilFound(tester, navItem('الرئيسية'));

    final cart = BlocProvider.of<CartBloc>(tester.element(find.byType(Scaffold).first));
    final stockBefore =
        (DemoDatabase.instance.row('products', 'p-1')!['stock'] as num).toInt();
    cart.add(const CartItemAdded(
      product: Product(
        id: 'p-1',
        sellerId: 'u-seller-1',
        title: 'منتج تجريبي',
        price: 25,
        stock: 5,
        sellerName: 'متجر تجريبي',
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await tapVisible(tester, navItem('السلة'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('سلة المشتريات'), findsOneWidget);
    expect(find.text('منتج تجريبي'), findsOneWidget);

    // إتمام الطلب والتأكيد.
    await tapVisible(tester, find.text('إتمام الطلب'));
    await tester.pump(const Duration(seconds: 2));
    final confirmButton = find.text('تأكيد الطلب (الدفع عند الوصول)');
    await tester.scrollUntilVisible(
      confirmButton,
      300,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 20,
    );
    await tapVisible(tester, confirmButton);
    await tapVisible(tester, find.text('تأكيد الطلب (الدفع عند الوصول)'));
    await pumpUntilFound(tester, find.textContaining('تم إنشاء طلبك بنجاح'));
    expect(find.textContaining('تم إنشاء طلبك بنجاح'), findsOneWidget);

    final stockAfter =
        (DemoDatabase.instance.row('products', 'p-1')!['stock'] as num).toInt();
    expect(stockAfter, stockBefore - 1);
  });
}
