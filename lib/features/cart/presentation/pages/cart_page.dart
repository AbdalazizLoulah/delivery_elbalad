import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../domain/entities/cart_line.dart';
import '../bloc/cart_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
/// صفحة السلة - بتجمع المنتجات حسب المتجر.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('سلة المشتريات'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) => state.lines.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: trOf(context, 'إفراغ السلة'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => context.read<CartBloc>().add(const CartCleared()),
                  ),
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.isLoading) return const LoadingView();
          if (state.lines.isEmpty) {
            return EmptyView(
              title: 'السلة فاضية',
              subtitle: 'ضيف منتجات من الصفحة الرئيسية وابدأ الطلب',
              icon: Icons.shopping_cart_outlined,
              actionLabel: 'اتفرج على المنتجات',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          final bySeller = state.summary.bySeller;
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padding = Responsive.horizontalPadding(constraints.maxWidth);
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: Responsive.maxContentWidth),
                        child: ListView(
                          padding: EdgeInsets.all(padding),
                          children: [
                            for (final entry in bySeller.entries) ...[
                              _SellerGroup(
                                sellerId: entry.key,
                                lines: entry.value,
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _CartSummaryBar(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _SellerGroup extends StatelessWidget {
  const _SellerGroup({required this.sellerId, required this.lines});

  final String sellerId;
  final List<CartLine> lines;

  @override
  Widget build(BuildContext context) {
    final sellerName = lines.first.product.sellerName;
    final subtotal = lines.fold<double>(0, (sum, line) => sum + line.total);

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: AppText(
                  sellerName.isEmpty ? 'متجر' : sellerName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              AppText(PriceTag.formatMoney(subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              IconButton(
                tooltip: trOf(context, 'حذف منتجات المتجر'),
                iconSize: 18,
                onPressed: () => context.read<CartBloc>().add(CartCleared(sellerId: sellerId)),
                icon: const Icon(Icons.close, color: AppColors.textHint),
              ),
            ],
          ),
          const Divider(height: 18),
          for (final line in lines) _CartLineTile(line: line),
        ],
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // على الشاشات الضيقة بنقسّم الصف على سطرين عشان مفيش تزحزح.
          final compact = constraints.maxWidth < 400;

          final image = AppNetworkImage(
            url: line.product.imageUrl,
            width: 54,
            height: 54,
            radius: 10,
          );
          final title = AppText(
            line.product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          );
          final price = PriceTag(price: line.product.price, fontSize: 13);
          final stepper = _QuantityStepper(
            quantity: line.quantity,
            onIncrease: line.quantity >= line.product.stock
                ? null
                : () => cart.add(CartQuantityChanged(
                      productId: line.product.id,
                      quantity: line.quantity + 1,
                    )),
            onDecrease: () => cart.add(CartQuantityChanged(
              productId: line.product.id,
              quantity: line.quantity - 1,
            )),
          );
          final remove = IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            onPressed: () => cart.add(CartItemRemoved(line.product.id)),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    image,
                    const SizedBox(width: 10),
                    Expanded(child: title),
                    remove,
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    stepper,
                    const Spacer(),
                    price,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              image,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 4),
                    price,
                  ],
                ),
              ),
              stepper,
              remove,
            ],
          );
        },
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, this.onIncrease, this.onDecrease});

  final int quantity;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ??
              Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Button(icon: Icons.remove, onTap: onDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AppText('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          _Button(icon: Icons.add, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? scheme.onSurfaceVariant.withValues(alpha: 0.5) : scheme.primary,
        ),
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = state.summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppText('${summary.itemsCount} منتج',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              AppText(Formatters.money(summary.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          AppPrimaryButton(
            label: 'إتمام الطلب',
            icon: Icons.arrow_forward,
            onPressed: () {
              if (state.lines.isEmpty) {
                showAppSnackBar(context, 'السلة فاضية', isError: true);
                return;
              }
              Navigator.of(context).pushNamed(AppRoutes.checkout);
            },
          ),
        ],
      ),
    );
  }
}
