// اختبار شامل لمسار التطبيق في الوضع التجريبي:
// شاشة البداية → اختيار الدور ← تسجيل دخول كل دور (مشتري / بائع / ديليفاري)
// → الشاشة الرئيسية بتاعته → تسجيل الخروج → الرجوع لاختيار الدور.
import 'package:delivery_elbalad/core/config/app_config.dart';
import 'package:delivery_elbalad/core/demo/demo_database.dart';
import 'package:delivery_elbalad/core/di/injector.dart';
import 'package:delivery_elbalad/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// العلامة المميزة لشاشة اختيار الدور.
final Finder rolesPageMarker = find.text('اختار نوع حسابك وابدأ حالًا');

/// قنوات الموقع الجغرافي: في بيئة الاختبار مفيش تنفيذ حقيقي، فبنسجّل موك
/// بيفشل فورًا (بدل ما الاستدعاء يعلق)، والتطبيق بيرجع لآخر موقع معروف.
void mockLocationChannels() {
  const channels = [
    MethodChannel('flutter.baseflow.com/geolocator'),
    MethodChannel('flutter.baseflow.com/geocoding'),
  ];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in channels) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException('مفيش تنفيذ حقيقي للقناة ${channel.name} في الاختبار');
    });
  }
}

/// بيعمل pump للفريمات (بخطوات 100ms) لحد ما العنصر يظهر،
/// وبيفشل الاختبار برسالة واضحة لو ظهرش بعد [maxAttempts] محاولة.
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

/// عنصر في الشريط السفلي (تجاهل أي عنصر بنفس الاسم في باقي الصفحة).
Finder navItem(String label) => find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );

/// بيوصّل العنصر للمنطقة المرئية قبل الضغط (بعض الصفحات أطول من الشاشة).
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// بيهيّئ التطبيق بالبيانات التجريبية من غير تشغيل محاكاة حركة الطيار
/// (علشان مايفضلش فيه Timer شغال بعد الاختبار).
Future<void> pumpApp(WidgetTester tester) async {
  mockLocationChannels();
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('ar');
  final preferences = await SharedPreferences.getInstance();
  AppConfig.forceDemoMode(true);
  await configureDependencies(preferences, startDemoSimulation: false);

  await tester.pumpWidget(const DeliveryElBaladApp());
  await pumpUntilFound(tester, rolesPageMarker);
}

/// بيسجل دخول من شاشة اختيار الدور بالدور المطلوب باستخدام أزرار الدخول السريع.
Future<void> signInAs(WidgetTester tester, String roleLabel) async {
  await tapVisible(tester, find.text('تسجيل الدخول'));
  await pumpUntilFound(tester, find.widgetWithText(ActionChip, roleLabel));

  await tapVisible(tester, find.widgetWithText(ActionChip, roleLabel));
  await tapVisible(tester, find.text('دخول'));
}

/// بيفتح تاب "حسابي" ويسجل الخروج وبيستنى الرجوع لشاشة اختيار الدور.
Future<void> signOut(WidgetTester tester) async {
  await tapVisible(tester, navItem('حسابي'));
  await pumpUntilFound(tester, find.text('ملفي الشخصي'));

  // صفحة الحساب أطول من الشاشة، فبنسحب لتحت لحد ما زرار الخروج يتبني.
  final signOutButton = find.text('تسجيل الخروج');
  await tester.scrollUntilVisible(
    signOutButton,
    250,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 20,
  );

  await tapVisible(tester, signOutButton);
  await pumpUntilFound(tester, rolesPageMarker);
}

void main() {
  testWidgets('رحلة الأدوار الثلاثة في الوضع التجريبي', (tester) async {
    await pumpApp(tester);

    // ---------------- المشتري ----------------
    await signInAs(tester, 'مشتري');
    await pumpUntilFound(tester, navItem('الرئيسية'));
    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('السلة'), findsOneWidget);

    await signOut(tester);

    // ---------------- البائع ----------------
    await signInAs(tester, 'بائع / متجر');
    await pumpUntilFound(tester, find.text('إجمالي المبيعات'));
    expect(navItem('لوحة المتجر'), findsOneWidget);
    expect(navItem('منتجاتي'), findsOneWidget);

    await signOut(tester);

    // ---------------- الطيار ----------------
    await signInAs(tester, 'ديليفاري');
    await pumpUntilFound(tester, find.text('أرباح اليوم'));
    expect(find.text('لوحة الطلبات'), findsOneWidget);
    expect(navItem('توصيلاتي'), findsOneWidget);

    await signOut(tester);

    di<DemoDatabase>().dispose();
  });
}
