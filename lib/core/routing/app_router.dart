import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/buyer/presentation/pages/buyer_shell_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/product_details_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/checkout_success_page.dart';
import '../../features/delivery/presentation/pages/courier_shell_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/orders/presentation/pages/buyer_orders_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/profile/presentation/pages/address_picker_page.dart';
import '../../features/profile/presentation/pages/addresses_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/seller/presentation/pages/seller_orders_page.dart';
import '../../features/seller/presentation/pages/seller_product_form_page.dart';
import '../../features/seller/presentation/pages/seller_products_page.dart';
import '../../features/seller/presentation/pages/seller_shell_page.dart';
import '../settings/settings_page.dart';
import '../widgets/feedback_widgets.dart';
import 'app_routes.dart';

import '../../core/localization/app_text.dart';
/// موجّه التطبيق: بيربط أسماء المسارات بالشاشات والباراميترات.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashPage(), settings);

      case AppRoutes.roles:
        return _page(const RoleSelectionPage(), settings);

      case AppRoutes.login:
        final role = settings.arguments is UserRole ? settings.arguments! as UserRole : null;
        return _page(LoginPage(role: role), settings);

      case AppRoutes.register:
        final role = settings.arguments is UserRole ? settings.arguments! as UserRole : UserRole.buyer;
        return _page(RegisterPage(role: role), settings);

      case AppRoutes.buyerHome:
        return _page(const BuyerShellPage(), settings);

      case AppRoutes.sellerHome:
        return _page(const SellerShellPage(), settings);

      case AppRoutes.courierHome:
      case AppRoutes.courierDashboard:
        return _page(const CourierShellPage(), settings);

      case AppRoutes.courierOrders:
        return _page(const CourierOrdersStandalonePage(), settings);

      case AppRoutes.productDetails:
        final args = settings.arguments;
        if (args is ProductDetailsArgs) {
          return _page(ProductDetailsPage(product: args.product), settings);
        }
        return _page(const _NotFoundPage(), settings);

      case AppRoutes.cart:
        return _page(const CartPage(), settings);

      case AppRoutes.favorites:
        return _page(const FavoritesPage(), settings);

      case AppRoutes.checkout:
        return _page(const CheckoutPage(), settings);

      case AppRoutes.checkoutSuccess:
        final orders = settings.arguments is List<Order> ? settings.arguments! as List<Order> : <Order>[];
        return _page(CheckoutSuccessPage(orders: orders), settings);

      case AppRoutes.buyerOrders:
        return _page(const BuyerOrdersPage(), settings);

      case AppRoutes.orderDetails:
        final args = settings.arguments;
        if (args is OrderDetailsArgs) {
          return _page(
            OrderDetailsPage(orderId: args.orderId, fromCourier: args.fromCourier),
            settings,
          );
        }
        return _page(const _NotFoundPage(), settings);

      case AppRoutes.sellerProducts:
        return _page(const SellerProductsPage(), settings);

      case AppRoutes.sellerOrders:
        return _page(const SellerOrdersPage(), settings);

      case AppRoutes.sellerProductForm:
        final args = settings.arguments is ProductFormArgs ? settings.arguments! as ProductFormArgs : null;
        return _page(SellerProductFormPage(product: args?.product), settings);

      case AppRoutes.profile:
        return _page(const ProfilePage(), settings);

      case AppRoutes.profileEdit:
        return _page(const ProfileEditPage(), settings);

      case AppRoutes.settings:
        return _page(const SettingsPage(), settings);

      case AppRoutes.notifications:
        return _page(const NotificationsPage(), settings);

      case AppRoutes.addresses:
        return _page(const AddressesPage(), settings);

      case AppRoutes.addressPicker:
        final args = settings.arguments is AddressPickerArgs
            ? settings.arguments! as AddressPickerArgs
            : const AddressPickerArgs();
        return _page<PickedAddress?>(
          AddressPickerPage(initialPoint: args.initialPoint, initialDetails: args.initialDetails),
          settings,
        );

      default:
        return _page(const _NotFoundPage(), settings);
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child, RouteSettings settings) =>
      MaterialPageRoute<T>(builder: (_) => child, settings: settings);
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('صفحة غير موجودة')),
      body: const ErrorView(message: 'المسار المطلوب غير موجود.'),
    );
  }
}
