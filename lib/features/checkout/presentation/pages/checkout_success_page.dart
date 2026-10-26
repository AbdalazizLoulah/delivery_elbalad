import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/utils/order_ui.dart';

import '../../../../core/localization/app_text.dart';
/// شاشة نجاح إنشاء الطلب.
class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({super.key, required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // في الشاشة القصيرة (أفقي) بنصغّر الأيقونة والفراغات.
            final compact = constraints.maxHeight < 480;
            final circle = compact ? 58.0 : 92.0;
            final glyph = compact ? 34.0 : 56.0;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 12 : 20),
                  child: Column(
                    children: [
                      SizedBox(height: compact ? 4 : 10),
                      Container(
                        width: circle,
                        height: circle,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_outline,
                            size: glyph, color: AppColors.success),
                      ),
                      SizedBox(height: compact ? 8 : 16),
                      AppText(
                        'تم إنشاء طلبك بنجاح 🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 17 : 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppText(
                        orders.length > 1
                            ? 'اتنشأت ${orders.length} طلبات (واحد لكل متجر)'
                            : 'المتجر هيبدأ يجهز طلبك حالًا',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: compact ? 10 : 20),
                      Expanded(
                        child: ListView.separated(
                          itemCount: orders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppText(order.sellerName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: order.status
                                              .colorFor(context)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: AppText(
                                          order.status.label,
                                          style: TextStyle(
                                              color: order.status.colorFor(context),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  AppText('كود الطلب: ${order.code}',
                                      style: const TextStyle(fontSize: 12.5)),
                                  AppText('${order.items.length} منتج',
                                      style: const TextStyle(fontSize: 12.5)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      AppText(order.paymentMethod.label,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary)),
                                      const Spacer(),
                                      AppText(Formatters.money(order.total),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  AppPrimaryButton(
                                    outlined: true,
                                    label: 'تتبع الطلب',
                                    onPressed: () {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        AppRoutes.orderDetails,
                                        (route) => route.isFirst,
                                        arguments: OrderDetailsArgs(orderId: order.id),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppPrimaryButton(
                        label: 'رجوع للرئيسية',
                        onPressed: () =>
                            Navigator.of(context).popUntil((route) => route.isFirst),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
