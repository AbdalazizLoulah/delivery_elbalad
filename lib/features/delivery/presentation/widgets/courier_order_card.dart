import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/widgets/order_card.dart';

import '../../../../core/localization/app_text.dart';
/// كارت الطلب في لوحة الطيار: بيوضح المتجر والعميل والمسافة والأرباح.
class CourierOrderCard extends StatelessWidget {
  const CourierOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.distanceToStoreKm,
    this.tripDistanceKm,
    this.earnings,
    this.footer,
    this.showStatus = true,
  });

  final Order order;
  final VoidCallback? onTap;

  /// المسافة من موقع الطيار لحد المتجر.
  final double? distanceToStoreKm;

  /// مسافة المشوار كامل (متجر → عميل).
  final double? tripDistanceKm;

  /// أرباح الطيار من الطلب.
  final double? earnings;

  final Widget? footer;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = theme.dividerTheme.color ?? theme.colorScheme.outlineVariant;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          order.storeName.isEmpty ? order.sellerName : order.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          '${order.code} • ${Formatters.timeAgo(order.createdAt)}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (showStatus) StatusChip(status: order.status, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_pin_circle_outlined,
                      size: 15, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppText(
                      order.addressDetails.isEmpty ? order.addressLabel : order.addressDetails,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (distanceToStoreKm != null)
                    _InfoChip(
                      icon: Icons.near_me_outlined,
                      label: 'منك للمتجر ${Formatters.distanceKm(distanceToStoreKm!)}',
                    ),
                  if (tripDistanceKm != null && tripDistanceKm! > 0)
                    _InfoChip(
                      icon: Icons.route_outlined,
                      label: 'المشوار ${Formatters.distanceKm(tripDistanceKm!)}',
                    ),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: order.isCash ? 'تحصيل كاش' : 'مدفوع أونلاين',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: AppColors.success),
                  const SizedBox(width: 2),
                  AppText(
                    'أرباحك ${Formatters.money(earnings ?? order.deliveryFee)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      fontSize: 13.5,
                    ),
                  ),
                  const Spacer(),
                  AppText(
                    'قيمة الطلب ${Formatters.money(order.total)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          AppText(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
