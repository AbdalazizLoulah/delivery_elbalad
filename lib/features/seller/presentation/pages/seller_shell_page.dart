import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/widgets/lazy_indexed_stack.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'seller_dashboard_page.dart';
import 'seller_orders_page.dart';
import 'seller_products_page.dart';

/// الشاشة الرئيسية للبائع: لوحة المتجر / الطلبات / المنتجات / حسابي.
class SellerShellPage extends StatefulWidget {
  const SellerShellPage({super.key});

  @override
  State<SellerShellPage> createState() => _SellerShellPageState();
}

class _SellerShellPageState extends State<SellerShellPage> {
  int _index = 0;
  final GlobalKey<SellerProductsPageState> _productsKey =
      GlobalKey<SellerProductsPageState>();

  void _selectTab(int value) {
    setState(() => _index = value);
    if (value == 2) _productsKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Scaffold(
      body: LazyIndexedStack(
        index: _index,
        children: [
          const SellerDashboardPage(),
          const SellerOrdersPage(),
          SellerProductsPage(key: _productsKey),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _selectTab,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: tr('لوحة المتجر', locale: locale),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: tr('الطلبات', locale: locale),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            activeIcon: const Icon(Icons.inventory_2),
            label: tr('منتجاتي', locale: locale),
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
}
