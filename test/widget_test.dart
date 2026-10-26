// اختبار واجهة بسيط: شاشة اختيار الدور لازم تعرض الأدوار التلاتة.
import 'package:delivery_elbalad/features/auth/presentation/pages/role_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('شاشة اختيار الدور بتعرض الأدوار التلاتة', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectionPage()),
    );

    expect(find.text('مشتري'), findsOneWidget);
    expect(find.text('بائع / متجر'), findsOneWidget);
    expect(find.text('ديليفاري'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
