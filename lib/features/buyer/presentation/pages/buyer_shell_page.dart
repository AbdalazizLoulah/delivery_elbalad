import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/widgets/lazy_indexed_stack.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../catalog/presentation/pages/buyer_home_page.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../orders/presentation/pages/buyer_orders_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

import '../../../../core/localization/app_text.dart';
/// الشاشة الرئيسية للمشتري: تصفح / طلباتي / المفضلة / السلة / حسابي.
class BuyerShellPage extends StatefulWidget {
  const BuyerShellPage({super.key});

  @override
  State<BuyerShellPage> createState() => _BuyerShellPageState();
}

class _BuyerShellPageState extends State<BuyerShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<CartBloc, int>((bloc) => bloc.state.summary.itemsCount);
    final favoritesCount = context.select<FavoritesBloc, int>((bloc) => bloc.state.ids.length);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      body: LazyIndexedStack(
        index: _index,
        children: const [
          BuyerHomePage(),
          BuyerOrdersPage(),
          FavoritesPage(),
          CartPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.storefront_outlined),
            activeIcon: const Icon(Icons.storefront),
            label: tr('الرئيسية', locale: locale),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: tr('طلباتي', locale: locale),
          ),
          BottomNavigationBarItem(
            icon: _badge(Icons.favorite_border, favoritesCount),
            activeIcon: _badge(Icons.favorite, favoritesCount),
            label: tr('المفضلة', locale: locale),
          ),
          BottomNavigationBarItem(
            icon: _badge(Icons.shopping_cart_outlined, cartCount),
            activeIcon: _badge(Icons.shopping_cart, cartCount),
            label: tr('السلة', locale: locale),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: tr('حسابي', locale: locale),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, int count) => Badge(
        isLabelVisible: count > 0,
        label: AppText('$count'),
        child: Icon(icon),
      );
}
