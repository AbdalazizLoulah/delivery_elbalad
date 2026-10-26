import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../bloc/favorites_bloc.dart';

import '../../../../core/localization/app_text.dart';
/// صفحة المفضلة.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('المفضلة')),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state.isLoading) return const LoadingView();
          if (state.products.isEmpty) {
            return const EmptyView(
              title: 'مفيش منتجات في المفضلة',
              subtitle: 'اضغط على القلب في أي منتج علشان تحفظه هنا',
              icon: Icons.favorite_border,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return ProductCard(
                product: product,
                isFavorite: true,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.productDetails,
                  arguments: ProductDetailsArgs(product),
                ),
                onToggleFavorite: () =>
                    context.read<FavoritesBloc>().add(FavoriteToggled(product)),
              );
            },
          );
        },
      ),
    );
  }
}
