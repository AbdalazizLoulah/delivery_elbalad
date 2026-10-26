import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_details_bloc.dart';
import '../widgets/product_card.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/utils/responsive.dart';
/// تفاصيل المنتج: صور، وصف، إضافة للسلة أو المفضلة.
class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.product});

  /// المنتج اللي جايّ من الصفحة السابقة (بيتعرض فورًا وبعدين يتحمّل الكامل).
  final Product product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<ProductDetailsBloc>()..add(ProductDetailsStarted(product.id)),
      child: _ProductDetailsView(initial: product),
    );
  }
}

class _ProductDetailsView extends StatefulWidget {
  const _ProductDetailsView({required this.initial});

  final Product initial;

  @override
  State<_ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<_ProductDetailsView> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    return Scaffold(
      appBar: AppBar(title: const AppText('تفاصيل المنتج')),
      body: BlocBuilder<ProductDetailsBloc, ProductDetailsState>(
        builder: (context, state) {
          if (state.product == null && state.errorMessage != null && !state.isLoading) {
            return ErrorView(message: state.errorMessage!);
          }
          final product = state.product ?? initial;
          return _Content(product: product, quantity: _quantity, onQuantityChanged: _setQuantity);
        },
      ),
    );
  }

  void _setQuantity(int value) {
    if (value < 1) return;
    setState(() => _quantity = value);
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesBloc>().state;
    final isFavorite = favorites.isFavorite(product.id);

    return Responsive.centerContent(ListView(
      padding: const EdgeInsets.all(14),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: AppNetworkImage(url: product.imageUrl, radius: 18),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppText(
                product.title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () {
                context.read<FavoritesBloc>().add(FavoriteToggled(product));
                showAppSnackBar(
                  context,
                  isFavorite ? 'اتشال من المفضلة' : 'اتضاف للمفضلة ❤️',
                  isSuccess: true,
                );
              },
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.danger : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            PriceTag(price: product.price, fontSize: 20),
            const Spacer(),
            RatingLine(rating: product.rating, count: product.reviewsCount),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            children: [
              if (product.sellerName.isNotEmpty)
                AttributeRow(
                  icon: Icons.storefront_outlined,
                  label: 'المتجر',
                  value: AppText(product.sellerName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              AttributeRow(
                icon: Icons.category_outlined,
                label: 'التصنيف',
                value: AppText(product.categoryName.isEmpty ? 'منتجات' : product.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              AttributeRow(
                icon: Icons.inventory_2_outlined,
                label: 'المتاح',
                value: AppText(
                  product.inStock ? '${product.stock} قطعة' : 'خلص من المخزن',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: product.inStock ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (product.description.isNotEmpty) ...[
          const SizedBox(height: 14),
          const AppText('الوصف', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          AppText(product.description,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            const AppText('الكمية', style: TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              onPressed: () => onQuantityChanged(quantity - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            AppText('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            IconButton(
              onPressed: quantity >= product.stock ? null : () => onQuantityChanged(quantity + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppPrimaryButton(
          label: 'ضيف للسلة',
          icon: Icons.add_shopping_cart,
          onPressed: product.inStock
              ? () {
                  context.read<CartBloc>().add(CartItemAdded(product: product, quantity: quantity));
                  showAppSnackBar(context, 'اتضاف للسلة 🛒', isSuccess: true);
                }
              : null,
        ),
        const SizedBox(height: 10),
        AppPrimaryButton(
          outlined: true,
          label: 'اشتري الآن',
          onPressed: product.inStock
              ? () {
                  context.read<CartBloc>().add(CartItemAdded(product: product, quantity: quantity));
                  Navigator.of(context).pushNamed(AppRoutes.checkout);
                }
              : null,
        ),
        const SizedBox(height: 12),
      ],
    ));
  }
}
