import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_user.dart';

/// بيانات العرض الخاصة بأدوار المستخدمين.
extension UserRoleUi on UserRole {
  String get label => switch (this) {
        UserRole.buyer => 'مشتري',
        UserRole.seller => 'بائع / متجر',
        UserRole.courier => 'ديليفاري',
      };

  String get description => switch (this) {
        UserRole.buyer => 'اتفرج على المنتجات، اطلب، وتابع الطلب لحد باب البيت',
        UserRole.seller => 'ضيف منتجاتك واستلم الطلبات وجهزها',
        UserRole.courier => 'شوف الطلبات القريبة منك ووصّلها وكسب',
      };

  IconData get icon => switch (this) {
        UserRole.buyer => Icons.shopping_cart_outlined,
        UserRole.seller => Icons.storefront_outlined,
        UserRole.courier => Icons.delivery_dining,
      };

  Color get color => switch (this) {
        UserRole.buyer => AppColors.primary,
        UserRole.seller => AppColors.info,
        UserRole.courier => AppColors.accent,
      };
}

extension UserUi on AppUser {
  Color get roleColor => role.color;

  String get ratingText => rating <= 0 ? 'جديد' : rating.toStringAsFixed(1);
}
