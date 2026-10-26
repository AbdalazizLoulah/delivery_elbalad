import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import '../../core/localization/app_text.dart';
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 12,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? _placeholder(context)
          : CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, _) => _placeholder(context, loading: true),
              errorWidget: (_, _, _) => _placeholder(context),
            ),
    );
  }

  Widget _placeholder(BuildContext context, {bool loading = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.image_outlined,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            AppText(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              AppText(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: FilledButton(onPressed: onAction, child: AppText(actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 12),
            AppText(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: 180, child: OutlinedButton(onPressed: onRetry, child: const AppText('إعادة المحاولة'))),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 12),
            AppText(label!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.onRatingChanged,
    this.count,
  });

  final double rating;
  final double size;
  final ValueChanged<int>? onRatingChanged;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onRatingChanged == null ? null : () => onRatingChanged!(i),
            child: Icon(
              i <= rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: AppColors.accent,
            ),
          ),
        if (count != null) ...[
          const SizedBox(width: 4),
          AppText('($count)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}
