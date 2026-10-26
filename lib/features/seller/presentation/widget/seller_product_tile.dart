import 'package:delivery_elbalad/core/theme/app_colors.dart';
import 'package:delivery_elbalad/core/utils/formatters.dart';
import 'package:delivery_elbalad/core/widgets/app_widgets.dart';
import 'package:delivery_elbalad/core/widgets/feedback_widgets.dart';
import 'package:delivery_elbalad/features/catalog/domain/entities/product.dart';
import 'package:delivery_elbalad/features/seller/presentation/bloc/seller_products_bloc.dart';
import 'package:delivery_elbalad/features/seller/presentation/pages/seller_products_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
class SellerProductTile extends StatelessWidget {
  const SellerProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppNetworkImage(
            url: product.imageUrl,
            width: 64,
            height: 64,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppText(Formatters.money(product.price),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    const SizedBox(width: 8),
                    AppText('متاح: ${product.stock}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.isActive
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        product.isActive ? 'ظاهر للعملاء' : 'مخفي',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: product.isActive ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: trOf(context, 'تعديل'),
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => openProductForm(context, product: product),
              ),
              IconButton(
                tooltip: trOf(context, 'حذف'),
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                onPressed: () => confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText('حذف المنتج'),
        content: AppText('متأكد إنك عايز تحذف "${product.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const AppText('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const AppText('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SellerProductsBloc>().add(SellerProductDeleted(product.id));
    }
  }
}
