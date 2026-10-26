import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../utils/order_ui.dart';

import '../../../../core/localization/app_text.dart';
/// شارة حالة الطلب.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.colorFor(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          AppText(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// كارت الطلب المستخدم في قوائم الطلبات (مشتري / بائع / طيار).
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showBuyer = false,
    this.trailing,
    this.subtitle,
    this.footer,
  });

  final Order order;
  final VoidCallback onTap;
  final bool showBuyer;
  final Widget? trailing;
  final String? subtitle;

  /// محتوى إضافي بيتحط أسفل الكارت (أزرار تحكم زي قبول/تجهيز الطلب).
  final Widget? footer;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          showBuyer
                              ? (order.buyerName.isEmpty ? 'عميل' : order.buyerName)
                              : order.sellerName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          '${order.code} • ${Formatters.timeAgo(order.createdAt)}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: order.status, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 34,
                    child: Row(
                      children: [
                        for (final item in order.items.take(3))
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 4),
                            child: AppNetworkImage(
                              url: item.imageUrl,
                              width: 34,
                              height: 34,
                              radius: 8,
                            ),
                          ),
                        if (order.items.length > 3)
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AppText('+${order.items.length - 3}',
                                style: const TextStyle(fontSize: 11.5)),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppText(
                    Formatters.money(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AppText(subtitle!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(order.paymentMethod.icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  AppText(order.paymentMethod.label,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(width: 10),
                  Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppText(
                      order.addressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                  ?trailing,
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
