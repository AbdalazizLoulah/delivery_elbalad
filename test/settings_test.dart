// اختبار الإعدادات: المظهر (فاتح/غامق/حسب النظام) واللغة (عربي/English).
import 'package:delivery_elbalad/core/localization/app_localization.dart';
import 'package:delivery_elbalad/core/settings/app_settings_cubit.dart';
import 'package:delivery_elbalad/core/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLocale.current = const Locale('ar');
  });

  test('الترجمة بتحوّل العربي لإنجليزي وبترجع زي ما هي في العربي', () {
    expect(tr('الرئيسية', locale: const Locale('en')), 'Home');
    expect(tr('السلة', locale: const Locale('en')), 'Cart');
    expect(tr('الرئيسية', locale: const Locale('ar')), 'الرئيسية');
    // الأرقام العربية-الهندية بتتحول لأرقام غربية في الإنجليزي.
    expect(tr('12 ج.م', locale: const Locale('en')), '12 EGP');
  });

  test('النصوص الديناميكية بتترجم كمان', () {
    expect(tr('3 منتج', locale: const Locale('en')), '3 items');
    expect(tr('طلب #250101-ABCD', locale: const Locale('en')), 'Order #250101-ABCD');
    expect(tr('كود الطلب: #250101-ABCD', locale: const Locale('en')),
        'Order code: #250101-ABCD');
    expect(tr('المتبقي 2.5 كم', locale: const Locale('en')), 'Remaining 2.5 km');
    expect(
      tr('اتنشأت 3 طلبات (واحد لكل متجر)', locale: const Locale('en')),
      '3 orders created (one per store)',
    );
  });

  testWidgets('صفحة الإعدادات بتبدّل المظهر واللغة', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final cubit = AppSettingsCubit(preferences);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: BlocProvider<AppSettingsCubit>.value(
          value: cubit,
          child: const SettingsPage(),
        ),
      ),
    );

    // المظهر: غامق
    await tester.tap(find.text('غامق'));
    await tester.pumpAndSettle();
    expect(cubit.state.themeMode, ThemeMode.dark);

    // المظهر: حسب النظام
    await tester.tap(find.text('حسب النظام'));
    await tester.pumpAndSettle();
    expect(cubit.state.themeMode, ThemeMode.system);

    // اللغة: English
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(cubit.state.locale.languageCode, 'en');
    expect(AppLocale.current.languageCode, 'en');

    // الاختيار بيتحفظ في التفضيلات.
    expect(preferences.getString('app_locale'), 'en');
    expect(preferences.getString('app_theme_mode'), 'system');
  });
}
