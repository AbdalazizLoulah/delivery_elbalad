import '../../features/auth/domain/entities/app_user.dart';
import '../../features/catalog/domain/entities/product.dart';

/// مسارات التطبيق.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String roles = '/roles';
  static const String login = '/login';
  static const String register = '/register';

  static const String buyerHome = '/buyer';
  static const String sellerHome = '/seller';
  static const String courierHome = '/courier';

  static const String productDetails = '/catalog/product';
  static const String cart = '/cart';
  static const String favorites = '/favorites';
  static const String checkout = '/checkout';
  static const String checkoutSuccess = '/checkout/success';
  static const String buyerOrders = '/orders';

  static const String orderDetails = '/orders/details';

  static const String sellerProducts = '/seller/products';
  static const String sellerOrders = '/seller/orders';
  static const String sellerProductForm = '/seller/products/form';

  static const String courierDashboard = '/courier/dashboard';
  static const String courierOrders = '/courier/orders';

  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String addresses = '/profile/addresses';
  static const String addressPicker = '/addresses/picker';

  /// الشاشة الرئيسية المناسبة لكل دور بعد تسجيل الدخول.
  static String homeForRole(UserRole role) => switch (role) {
        UserRole.buyer => buyerHome,
        UserRole.seller => sellerHome,
        UserRole.courier => courierHome,
      };
}

/// باراميترات المسارات المحددة.
class ProductDetailsArgs {
  const ProductDetailsArgs(this.product);

  final Product product;
}

class OrderDetailsArgs {
  const OrderDetailsArgs({required this.orderId, this.fromCourier = false});

  final String orderId;
  final bool fromCourier;
}

class RoleArgs {
  const RoleArgs(this.role);

  final UserRole role;
}

class ProductFormArgs {
  const ProductFormArgs({this.product});

  final Product? product;
}

/// عنوان مختار من الخريطة.
class PickedAddress {
  const PickedAddress({
    required this.lat,
    required this.lng,
    required this.label,
    required this.details,
    this.savedAddressId,
  });

  final double lat;
  final double lng;
  final String label;
  final String details;
  final String? savedAddressId;
}

class AddressPickerArgs {
  const AddressPickerArgs({this.initialPoint, this.initialDetails});

  final LatLngLike? initialPoint;
  final String? initialDetails;
}

/// بديل بسيط لـ LatLng بدون الاعتماد على مكتبة الخرائط في طبقة التوجيه.
class LatLngLike {
  const LatLngLike(this.lat, this.lng);

  final double lat;
  final double lng;
}
