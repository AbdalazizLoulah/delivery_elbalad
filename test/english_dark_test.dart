// اختبار التشغيل الكامل بالإنجليزي + الوضع الغامق (RTL/LTR + الثيم).
import 'package:delivery_elbalad/core/config/app_config.dart';
import 'package:delivery_elbalad/core/demo/demo_database.dart';
import 'package:delivery_elbalad/core/di/injector.dart';
import 'package:delivery_elbalad/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      throw MissingPluginException('مفيش تنفيذ حقيقي للقناة ${channel.name}');
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
  fail('العنصر ما ظهرش على الشاشة: $finder');
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('التطبيق بيشتغل بالإنجليزي والوضع الغامق', (tester) async {
    mockLocationChannels();
    // التفضيلات: إنجليزي + غامق.
    SharedPreferences.setMockInitialValues({
      'app_locale': 'en',
      'app_theme_mode': 'dark',
    });
    await initializeDateFormatting();
    final preferences = await SharedPreferences.getInstance();
    AppConfig.forceDemoMode(true);
    await configureDependencies(preferences, startDemoSimulation: false);

    await tester.pumpWidget(const DeliveryElBaladApp());

    // شاشة اختيار الدور بالإنجليزي.
    await pumpUntilFound(tester, find.text('Choose your account type and get started'));
    expect(find.text('Buyer'), findsOneWidget);
    expect(find.text('Seller / Store'), findsOneWidget);
    expect(find.text('Courier'), findsOneWidget);

    // الدخول كمشتري.
    await tapVisible(tester, find.text('Log in'));
    await pumpUntilFound(tester, find.widgetWithText(ActionChip, 'Buyer'));
    await tapVisible(tester, find.widgetWithText(ActionChip, 'Buyer'));
    await tapVisible(tester, find.text('Sign in'));

    // شريط التنقل بالإنجليزي + الاتجاه LTR.
    await pumpUntilFound(tester, find.text('Home'));
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('My Account'), findsOneWidget);

    final context = tester.element(find.text('Home').first);
    expect(Directionality.of(context), TextDirection.ltr);
    expect(Theme.of(context).brightness, Brightness.dark);

    di<DemoDatabase>().dispose();
  });
}
