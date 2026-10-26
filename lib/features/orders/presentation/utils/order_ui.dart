import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../domain/entities/order.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
/// تجميع كل معلومات العرض الخاصة بحالة الطلب في مكان واحد.
extension OrderStatusUi on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pendingSeller => 'بانتظار موافقة المتجر',
        OrderStatus.confirmed => 'المتجر قبل الطلب',
        OrderStatus.preparing => 'جاري التجهيز',
        OrderStatus.readyForPickup => 'جاهز للاستلام',
        OrderStatus.assigned => 'طيار في الطريق للمتجر',
        OrderStatus.pickedUp => 'الطيار استلم الطلب',
        OrderStatus.onTheWay => 'في الطريق إليك',
        OrderStatus.delivered => 'تم التسليم',
        OrderStatus.cancelled => 'ملغي',
      };

  String get description => switch (this) {
        OrderStatus.pendingSeller => 'المتجر بيجهز الموافقة على طلبك',
        OrderStatus.confirmed => 'طلبك مقبول وجاري التحضير',
        OrderStatus.preparing => 'بنحضر منتجاتك حالًا',
        OrderStatus.readyForPickup => 'الطلب مستني الطيار يستلمه',
        OrderStatus.assigned => 'طيار متاح قبل الطلب وهو رايح للمتجر',
        OrderStatus.pickedUp => 'الطيار استلم الطلب وبدأ التوصيل',
        OrderStatus.onTheWay => 'تابع الطيار لحظة بلحظة على الخريطة',
        OrderStatus.delivered => 'وصل الطلب لباب البيت 🎉',
        OrderStatus.cancelled => 'الطلب اتلغى',
      };

  Color get color => switch (this) {
        OrderStatus.pendingSeller => AppColors.warning,
        OrderStatus.confirmed || OrderStatus.preparing => AppColors.info,
        OrderStatus.readyForPickup => AppColors.primary,
        OrderStatus.assigned || OrderStatus.pickedUp => AppColors.accent,
        OrderStatus.onTheWay => AppColors.success,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.danger,
      };

  /// لون الحالة مناسب للوضع الحالي (في الغامق بنستخدم نسخة أفتح).
  Color colorFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.lighten(color)
          : color;

  IconData get icon => switch (this) {
        OrderStatus.pendingSeller => Icons.hourglass_empty,
        OrderStatus.confirmed => Icons.verified_outlined,
        OrderStatus.preparing => Icons.shopping_basket_outlined,
        OrderStatus.readyForPickup => Icons.storefront_outlined,
        OrderStatus.assigned => Icons.person_pin_circle_outlined,
        OrderStatus.pickedUp => Icons.inventory_2_outlined,
        OrderStatus.onTheWay => Icons.delivery_dining,
        OrderStatus.delivered => Icons.check_circle_outline,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  /// ترتيب الخطوة في شريط التتبع (بلا الإلغاء).
  int get stepIndex => switch (this) {
        OrderStatus.pendingSeller => 0,
        OrderStatus.confirmed => 1,
        OrderStatus.preparing => 2,
        OrderStatus.readyForPickup => 3,
        OrderStatus.assigned => 4,
        OrderStatus.pickedUp => 5,
        OrderStatus.onTheWay => 6,
        OrderStatus.delivered => 7,
        OrderStatus.cancelled => -1,
      };

  static const List<OrderStatus> trackSteps = [
    OrderStatus.pendingSeller,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.assigned,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
  ];
}

extension PaymentMethodUi on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cashOnDelivery => 'الدفع عند الوصول',
        PaymentMethod.visa => 'بطاقة فيزا / ماستركارد',
      };

  String get description => switch (this) {
        PaymentMethod.cashOnDelivery => 'بتدفع كاش للمندوب وقت التسليم',
        PaymentMethod.visa => 'دفع أونلاين آمن بالكارت',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cashOnDelivery => Icons.payments_outlined,
        PaymentMethod.visa => Icons.credit_card,
      };
}

extension PaymentStatusUi on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.unpaid => 'غير مدفوع',
        PaymentStatus.paid => 'مدفوع',
        PaymentStatus.refunded => 'مسترجع',
      };

  Color get color => switch (this) {
        PaymentStatus.unpaid => AppColors.warning,
        PaymentStatus.paid => AppColors.success,
        PaymentStatus.refunded => AppColors.danger,
      };
}

/// نتيجة تقييم الطيار من الديالوج.
class CourierRatingInput {
  const CourierRatingInput({required this.rating, required this.comment});

  final int rating;
  final String comment;
}

/// ديالوج تقييم الطيار — مستخدم من تفاصيل الطلب وقائمة الطلبات.
Future<CourierRatingInput?> showCourierRatingDialog(
  BuildContext context, {
  int initialRating = 5,
}) async {
  var rating = initialRating.clamp(1, 5);
  final commentController = TextEditingController();
  final result = await showDialog<CourierRatingInput>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const AppText('تقييم الطيار'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                'قيّم تجربتك مع الطيار وساعدنا نقدم خدمة أحسن.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              RatingStars(
                rating: rating.toDouble(),
                size: 34,
                onRatingChanged: (value) => setState(() => rating = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 300,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: trOf(context, 'اكتب تعليقك (اختياري)'),
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const AppText('بعدين'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              CourierRatingInput(
                rating: rating,
                comment: commentController.text.trim(),
              ),
            ),
            child: const AppText('إرسال التقييم'),
          ),
        ],
      ),
    ),
  );
  commentController.dispose();
  return result;
}
