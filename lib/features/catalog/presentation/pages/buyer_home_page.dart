import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../domain/entities/product.dart';
import '../bloc/catalog_bloc.dart';
import '../widgets/product_card.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
/// الصفحة الرئيسية للمشتري: تصنيفات + بحث + المنتجات.
class BuyerHomePage extends StatelessWidget {
  const BuyerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<CatalogBloc>()..add(const CatalogStarted()),
      child: const _BuyerHomeView(),
    );
  }
}

class _BuyerHomeView extends StatefulWidget {
  const _BuyerHomeView();

  @override
  State<_BuyerHomeView> createState() => _BuyerHomeViewState();
}

class _BuyerHomeViewState extends State<_BuyerHomeView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('ديليفاري البلد'),
        automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<FavoritesBloc, FavoritesState>(
            buildWhen: (previous, current) => previous.ids.length != current.ids.length,
            builder: (context, state) => IconButton(
              tooltip: trOf(context, 'المفضلة'),
              icon: Badge(
                isLabelVisible: state.ids.isNotEmpty,
                label: AppText('${state.ids.length}'),
                child: const Icon(Icons.favorite_border),
              ),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.favorites),
            ),
          ),
        ],
      ),
      body: BlocConsumer<CatalogBloc, CatalogState>(
        listenWhen: (previous, current) => current.errorMessage != null,
        listener: (context, state) => showAppSnackBar(context, state.errorMessage ?? '', isError: true),
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CatalogBloc>().add(const CatalogStarted());
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = Responsive.gridColumns(width);
                final padding = Responsive.horizontalPadding(width);
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _SearchBar(controller: _searchController)),
                    SliverToBoxAdapter(child: _CategoriesRow(state: state)),
                    if (state.isLoading && state.products.isEmpty)
                      const SliverFillRemaining(child: LoadingView(label: 'بنجهز المنتجات...'))
                    else if (state.products.isEmpty)
                      SliverFillRemaining(
                        child: EmptyView(
                          title: 'مفيش منتجات مطابقة',
                          subtitle: 'جرّب تبحث بكلمة تانية أو اختار تصنيف مختلف',
                          icon: Icons.search_off,
                          actionLabel: 'إعادة التحميل',
                          onAction: () => context.read<CatalogBloc>().add(const CatalogStarted()),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(padding, 4, padding, 90),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: Responsive.gridAspectRatio(width, columns),
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = state.products[index];
                              return _ProductTile(product: product);
                            },
                            childCount: state.products.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) =>
            context.read<CatalogBloc>().add(CatalogSearchChanged(value.trim())),
        decoration: InputDecoration(
          hintText: trOf(context, 'بتدور على إيه النهاردة؟'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
              context.read<CatalogBloc>().add(const CatalogSearchChanged(''));
            },
          ),
        ),
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.state});

  final CatalogState state;

  @override
  Widget build(BuildContext context) {
    if (state.categories.isEmpty) return const SizedBox(height: 8);

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: const AppText('الكل'),
              selected: state.selectedCategoryId == null,
              onSelected: (_) => context.read<CatalogBloc>().add(const CatalogCategorySelected(null)),
            ),
          ),
          for (final category in state.categories)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: AppText('${category.icon} ${category.name}'),
                selected: state.selectedCategoryId == category.id,
                onSelected: (_) =>
                    context.read<CatalogBloc>().add(CatalogCategorySelected(category.id)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesBloc>().state;
    return ProductCard(
      product: product,
      isFavorite: favorites.isFavorite(product.id),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.productDetails,
        arguments: ProductDetailsArgs(product),
      ),
      onToggleFavorite: () {
        context.read<FavoritesBloc>().add(FavoriteToggled(product));
        showAppSnackBar(
          context,
          favorites.isFavorite(product.id) ? 'اتشال من المفضلة' : 'اتضاف للمفضلة ❤️',
          isSuccess: true,
        );
      },
      onAddToCart: () {
        context.read<CartBloc>().add(CartItemAdded(product: product));
        showAppSnackBar(context, 'اتضاف للسلة 🛒', isSuccess: true);
      },
    );
  }
}
