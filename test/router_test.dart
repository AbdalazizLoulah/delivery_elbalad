import 'package:delivery_elbalad/core/routing/app_router.dart';
import 'package:delivery_elbalad/core/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('مسار اختيار العنوان بيطلع Route<PickedAddress?> عشان pushNamed يشتغل', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.addressPicker),
    );

    expect(route, isA<Route<PickedAddress?>>());
  });

  test('المسارات العادية بتشتغل من غير نوع نتيجة محدد', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.login),
    );

    expect(route, isA<Route<dynamic>>());
  });
}
