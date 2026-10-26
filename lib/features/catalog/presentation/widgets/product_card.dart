import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../catalog/domain/entities/product.dart';

import '../../../../core/localization/app_text.dart';
/// كارت المنتج في الشبكة.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onToggleFavorite,
    this.isFavorite = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: AppNetworkImage(
                      url: product.imageUrl,
                      fit: BoxFit.cover,
                      radius: 16,
                    ),
                  ),
                  if (onToggleFavorite != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Material(
                        color: theme.colorScheme.surface,
                        shape: const CircleBorder(),
                        child: IconButton(
                          iconSize: 18,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: onToggleFavorite,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.danger
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  if (!product.inStock)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const AppText('خلص',
                            style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    const SizedBox(height: 4),
                    if (product.sellerName.isNotEmpty)
                      AppText(
                        product.sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: PriceTag(price: product.price)),
                        if (onAddToCart != null)
                          Material(
                            color: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: product.inStock ? onAddToCart : null,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add,
                                  color: theme.colorScheme.onPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.price, this.strikeThrough, this.fontSize = 14});

  final double price;
  final double? strikeThrough;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppText(
          formatMoney(price),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            color: AppColors.primaryDark,
          ),
        ),
        if (strikeThrough != null) ...[
          const SizedBox(width: 6),
          AppText(
            formatMoney(strikeThrough!),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  static String formatMoney(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$text ج.م';
  }
}

/// صف يوضح تقييم المنتج.
class AttributeRow extends StatelessWidget {
  const AttributeRow({super.key, required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final Widget? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          AppText(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          value ??
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
        ],
      ),
    );
  }
}

/// تقييم نجوم صغير للعرض فقط.
class RatingLine extends StatelessWidget {
  const RatingLine({super.key, required this.rating, this.count, this.size = 14});

  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RatingStars(rating: rating, count: count, size: size);
  }
}
