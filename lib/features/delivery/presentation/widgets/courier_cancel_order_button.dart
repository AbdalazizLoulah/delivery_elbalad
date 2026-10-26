import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/delivery_orders_bloc.dart';

import '../../../../core/localization/app_text.dart';
/// زرار إلغاء الطلب من الطيار.
///
/// الطيار يقدر يلغي الطلب **فقط** لو الدفع عند الاستلام (كاش عند الوصول)،
/// لأن الطلبات المدفوعة أونلاين الفلوس اتدفعت بالفعل ومينفعش تتلغى.
class CourierCancelOrderButton extends StatelessWidget {
  const CourierCancelOrderButton({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final isUpdating =
        context.watch<DeliveryOrdersBloc>().state.updatingOrderId == order.id;

    if (!order.canCourierCancel) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.textHint),
            SizedBox(width: 5),
            Expanded(
              child: AppText(
                'الإلغاء متاح للطلبات "الدفع عند الاستلام" فقط — الطلب دا مدفوع أونلاين.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.danger,
          minimumSize: const Size.fromHeight(42),
        ),
        onPressed: isUpdating ? null : () => _confirm(context),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const AppText('إلغاء الطلب (الدفع عند الاستلام)'),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<DeliveryOrdersBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText('إلغاء الطلب'),
        content: AppText(
          'متأكد إنك عايز تلغي الطلب ${order.code}؟\n'
          'الطلب دا الدفع عند الاستلام، فمفيش أي مبالغ اتدفعت.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText('رجوع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AppText('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(DeliveryOrderCancelled(order));
    }
  }
}
