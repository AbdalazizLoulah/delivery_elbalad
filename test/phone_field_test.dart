// اختبار ترتيب حقل الموبايل (بلد + رقم) على الشاشات الضيقة والواسعة.
import 'package:delivery_elbalad/core/utils/countries.dart';
import 'package:delivery_elbalad/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildPhoneField({
  required double width,
  required TextEditingController controller,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: AppPhoneField(
            controller: controller,
            country: Countries.egypt,
            onCountryChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('على الشاشة الضيقة البلد فوق الرقم من غير Overflow', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildPhoneField(width: 300, controller: controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppCountryDropdown), findsOneWidget);
    expect(find.byType(AppTextField), findsOneWidget);

    final countryY = tester.getCenter(find.byType(AppCountryDropdown)).dy;
    final phoneY = tester.getCenter(find.byType(AppTextField)).dy;
    expect(phoneY, greaterThan(countryY));
  });

  testWidgets('على الشاشة الواسعة البلد والرقم جنب بعض', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildPhoneField(width: 420, controller: controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final countryY = tester.getCenter(find.byType(AppCountryDropdown)).dy;
    final phoneY = tester.getCenter(find.byType(AppTextField)).dy;
    expect((phoneY - countryY).abs(), lessThan(20));
  });
}
