import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_cache.dart';
import '../../features/auth/data/datasources/auth_data_source.dart';
import '../../features/auth/data/datasources/local_auth_data_source.dart';
import '../../features/auth/data/datasources/supabase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/presentation/bloc/notifications_cubit.dart';
import '../../features/cart/data/datasources/cart_local_data_source.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/cart_usecases.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/catalog/data/datasources/catalog_data_source.dart';
import '../../features/catalog/data/datasources/local_catalog_data_source.dart';
import '../../features/catalog/data/datasources/supabase_catalog_data_source.dart';
import '../../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/catalog/domain/usecases/catalog_usecases.dart';
import '../../features/catalog/presentation/bloc/catalog_bloc.dart';
import '../../features/catalog/presentation/bloc/product_details_bloc.dart';
import '../../features/checkout/presentation/bloc/checkout_bloc.dart';
import '../../features/delivery/domain/usecases/delivery_usecases.dart';
import '../../features/delivery/presentation/bloc/delivery_orders_bloc.dart';
import '../../features/favorites/domain/usecases/favorites_usecases.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/orders/data/datasources/local_order_data_source.dart';
import '../../features/orders/data/datasources/order_data_source.dart';
import '../../features/orders/data/datasources/supabase_order_data_source.dart';
import '../../features/orders/data/repositories/buyer_order_repository_impl.dart';
import '../../features/orders/data/repositories/courier_order_repository_impl.dart';
import '../../features/orders/data/repositories/seller_order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/usecases/order_usecases.dart';
import '../../features/orders/presentation/bloc/buyer_orders_bloc.dart';
import '../../features/orders/presentation/bloc/order_tracking_bloc.dart';
import '../../features/profile/data/datasources/local_profile_data_source.dart';
import '../../features/profile/data/datasources/profile_data_source.dart';
import '../../features/profile/data/datasources/supabase_profile_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecases.dart';
import '../../features/profile/presentation/bloc/addresses_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/seller/presentation/bloc/seller_orders_bloc.dart';
import '../../features/seller/presentation/bloc/seller_products_bloc.dart';
import '../config/app_config.dart';
import '../demo/demo_database.dart';
import '../services/location_service.dart';
import '../settings/app_settings_cubit.dart';
import '../services/route_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_provider.dart';

/// حاوية الاعتماديات (Dependency Injection Container).
///
/// كل الطبقات بتتوصّل هنا فقط، والـ UI بينده على الـ Blocs وخلاص.
final GetIt di = GetIt.instance;

Future<void> configureDependencies(
  SharedPreferences preferences, {
  bool startDemoSimulation = true,
}) async {
  // ---------------- Core ----------------
  di.registerSingleton<SharedPreferences>(preferences);
  di.registerLazySingleton<AppSettingsCubit>(() => AppSettingsCubit(preferences));
  di.registerLazySingleton<NotificationService>(() => NotificationService());
  di.registerLazySingleton<NotificationsCubit>(() => NotificationsCubit(preferences));
  di.registerLazySingleton<SupabaseProvider>(() => SupabaseProvider());
  di.registerLazySingleton<LocationService>(
    () => GeolocatorLocationService(di<SharedPreferences>()),
  );
  di.registerLazySingleton<RouteService>(() => const RouteService());
  di.registerLazySingleton<GeocodingService>(() => const PlatformGeocodingService());
  di.registerLazySingleton<StorageService>(
    () => AppConfig.isDemoMode
        ? const UnsupportedStorageService()
        : SupabaseStorageService(di<SupabaseProvider>()),
  );

  final demoDatabase = DemoDatabase.instance;
  if (AppConfig.isDemoMode) {
    demoDatabase.seed();
    final savedDemoUser = preferences.getString('demo_current_user_id');
    if (savedDemoUser != null) demoDatabase.currentUserId = savedDemoUser;
  }
  di.registerSingleton<DemoDatabase>(demoDatabase);
  if (AppConfig.isDemoMode && startDemoSimulation) demoDatabase.startDemoRide();

  // ---------------- Data sources ----------------
  if (AppConfig.isDemoMode) {
    di.registerLazySingleton<AuthDataSource>(
      () => LocalAuthDataSource(di<DemoDatabase>(), di<SharedPreferences>()),
    );
    di.registerLazySingleton<CatalogDataSource>(
      () => LocalCatalogDataSource(di<DemoDatabase>()),
    );
    di.registerLazySingleton<ProfileDataSource>(
      () => LocalProfileDataSource(di<DemoDatabase>()),
    );
    di.registerLazySingleton<OrderDataSource>(() => LocalOrderDataSource(di<DemoDatabase>()));
  } else {
    di.registerLazySingleton<AuthDataSource>(
      () => SupabaseAuthDataSource(di<SupabaseProvider>()),
    );
    di.registerLazySingleton<CatalogDataSource>(
      () => SupabaseCatalogDataSource(di<SupabaseProvider>()),
    );
    di.registerLazySingleton<ProfileDataSource>(
      () => SupabaseProfileDataSource(di<SupabaseProvider>()),
    );
    di.registerLazySingleton<OrderDataSource>(
      () => SupabaseOrderDataSource(di<SupabaseProvider>()),
    );
  }

  di.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSource(di<SharedPreferences>()),
  );
  di.registerLazySingleton<FavoritesLocalDataSource>(
    () => FavoritesLocalDataSource(di<SharedPreferences>()),
  );

  // ---------------- Repositories ----------------
  di.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      di<AuthDataSource>(),
      AuthCache(di<SharedPreferences>()),
    ),
  );
  di.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(di<ProfileDataSource>()),
  );
  di.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(di<CatalogDataSource>()),
  );
  di.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(di<CartLocalDataSource>()));
  di.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(di<FavoritesLocalDataSource>()),
  );
  di.registerLazySingleton<OrderRepository>(
    () => BuyerOrderRepositoryImpl(di<OrderDataSource>()),
  );
  di.registerLazySingleton<SellerOrderRepository>(
    () => SellerOrderRepositoryImpl(di<OrderDataSource>()),
  );
  di.registerLazySingleton<CourierOrderRepository>(
    () => CourierOrderRepositoryImpl(di<OrderDataSource>()),
  );

  // ---------------- Use cases: auth ----------------
  di.registerLazySingleton<SignInUseCase>(() => SignInUseCase(di<AuthRepository>()));
  di.registerLazySingleton<SignUpUseCase>(() => SignUpUseCase(di<AuthRepository>()));
  di.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(di<AuthRepository>()));
  di.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(di<AuthRepository>()),
  );
  di.registerLazySingleton<WatchAuthStateUseCase>(
    () => WatchAuthStateUseCase(di<AuthRepository>()),
  );

  // ---------------- Use cases: catalog ----------------
  di.registerLazySingleton<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(di<CatalogRepository>()),
  );
  di.registerLazySingleton<GetProductsUseCase>(() => GetProductsUseCase(di<CatalogRepository>()));
  di.registerLazySingleton<GetProductDetailsUseCase>(
    () => GetProductDetailsUseCase(di<CatalogRepository>()),
  );
  di.registerLazySingleton<SaveProductUseCase>(() => SaveProductUseCase(di<CatalogRepository>()));
  di.registerLazySingleton<DeleteProductUseCase>(
    () => DeleteProductUseCase(di<CatalogRepository>()),
  );

  // ---------------- Use cases: cart & favorites ----------------
  di.registerLazySingleton<LoadCartUseCase>(() => LoadCartUseCase(di<CartRepository>()));
  di.registerLazySingleton<SaveCartUseCase>(() => SaveCartUseCase(di<CartRepository>()));
  di.registerLazySingleton<LoadFavoritesUseCase>(
    () => LoadFavoritesUseCase(di<FavoritesRepository>()),
  );
  di.registerLazySingleton<SaveFavoritesUseCase>(
    () => SaveFavoritesUseCase(di<FavoritesRepository>()),
  );

  // ---------------- Use cases: orders ----------------
  di.registerLazySingleton<PlaceOrderUseCase>(() => PlaceOrderUseCase(di<OrderRepository>()));
  di.registerLazySingleton<GetBuyerOrdersUseCase>(
    () => GetBuyerOrdersUseCase(di<OrderRepository>()),
  );
  di.registerLazySingleton<GetOrderDetailsUseCase>(
    () => GetOrderDetailsUseCase(di<OrderRepository>()),
  );
  di.registerLazySingleton<WatchOrderUseCase>(() => WatchOrderUseCase(di<OrderRepository>()));
  di.registerLazySingleton<CancelOrderUseCase>(() => CancelOrderUseCase(di<OrderRepository>()));
  di.registerLazySingleton<RateDeliveryUseCase>(() => RateDeliveryUseCase(di<OrderRepository>()));
  di.registerLazySingleton<GetSellerOrdersUseCase>(
    () => GetSellerOrdersUseCase(di<SellerOrderRepository>()),
  );
  di.registerLazySingleton<UpdateOrderStatusUseCase>(
    () => UpdateOrderStatusUseCase(di<SellerOrderRepository>()),
  );

  // ---------------- Use cases: delivery ----------------
  di.registerLazySingleton<GetNearbyOrdersUseCase>(
    () => GetNearbyOrdersUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<GetOfferedOrdersUseCase>(
    () => GetOfferedOrdersUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<GetCourierOrdersUseCase>(
    () => GetCourierOrdersUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<AcceptOrderUseCase>(
    () => AcceptOrderUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<UpdateDeliveryStatusUseCase>(
    () => UpdateDeliveryStatusUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<CancelDeliveryOrderUseCase>(
    () => CancelDeliveryOrderUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<PushCourierLocationUseCase>(
    () => PushCourierLocationUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<WatchCourierLocationUseCase>(
    () => WatchCourierLocationUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<SetAvailabilityUseCase>(
    () => SetAvailabilityUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<GetAvailableCouriersUseCase>(
    () => GetAvailableCouriersUseCase(di<CourierOrderRepository>()),
  );
  di.registerLazySingleton<AssignNearestCourierUseCase>(
    () => AssignNearestCourierUseCase(
      couriers: di<CourierOrderRepository>(),
      orders: di<OrderRepository>(),
    ),
  );

  // ---------------- Use cases: profile ----------------
  di.registerLazySingleton<GetProfileUseCase>(() => GetProfileUseCase(di<ProfileRepository>()));
  di.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(di<ProfileRepository>()),
  );
  di.registerLazySingleton<GetAddressesUseCase>(
    () => GetAddressesUseCase(di<ProfileRepository>()),
  );
  di.registerLazySingleton<SaveAddressUseCase>(() => SaveAddressUseCase(di<ProfileRepository>()));
  di.registerLazySingleton<DeleteAddressUseCase>(
    () => DeleteAddressUseCase(di<ProfileRepository>()),
  );

  // ---------------- Blocs ----------------
  di.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      signIn: di<SignInUseCase>(),
      signUp: di<SignUpUseCase>(),
      signOut: di<SignOutUseCase>(),
      getCurrentUser: di<GetCurrentUserUseCase>(),
      watchAuthState: di<WatchAuthStateUseCase>(),
    )..add(const AuthStarted()),
  );

  di.registerFactory<CatalogBloc>(
    () => CatalogBloc(
      getCategories: di<GetCategoriesUseCase>(),
      getProducts: di<GetProductsUseCase>(),
    ),
  );
  di.registerFactory<ProductDetailsBloc>(
    () => ProductDetailsBloc(getProductDetails: di<GetProductDetailsUseCase>()),
  );
  di.registerFactory<CartBloc>(
    () => CartBloc(loadCart: di<LoadCartUseCase>(), saveCart: di<SaveCartUseCase>()),
  );
  di.registerFactory<FavoritesBloc>(
    () => FavoritesBloc(
      loadFavorites: di<LoadFavoritesUseCase>(),
      saveFavorites: di<SaveFavoritesUseCase>(),
      getProducts: di<GetProductsUseCase>(),
    ),
  );
  di.registerFactory<CheckoutBloc>(
    () => CheckoutBloc(
      getAddresses: di<GetAddressesUseCase>(),
      saveAddress: di<SaveAddressUseCase>(),
      placeOrder: di<PlaceOrderUseCase>(),
      locationService: di<LocationService>(),
      geocodingService: di<GeocodingService>(),
    ),
  );
  di.registerFactory<BuyerOrdersBloc>(
    () => BuyerOrdersBloc(
      getBuyerOrders: di<GetBuyerOrdersUseCase>(),
      cancelOrder: di<CancelOrderUseCase>(),
    ),
  );
  di.registerFactory<OrderTrackingBloc>(
    () => OrderTrackingBloc(
      getOrderDetails: di<GetOrderDetailsUseCase>(),
      watchOrder: di<WatchOrderUseCase>(),
      watchCourierLocation: di<WatchCourierLocationUseCase>(),
      rateDelivery: di<RateDeliveryUseCase>(),
      routeService: di<RouteService>(),
    ),
  );
  di.registerFactory<SellerOrdersBloc>(
    () => SellerOrdersBloc(
      getSellerOrders: di<GetSellerOrdersUseCase>(),
      updateOrderStatus: di<UpdateOrderStatusUseCase>(),
      assignNearestCourier: di<AssignNearestCourierUseCase>(),
    ),
  );
  di.registerFactory<SellerProductsBloc>(
    () => SellerProductsBloc(
      getProducts: di<GetProductsUseCase>(),
      saveProduct: di<SaveProductUseCase>(),
      deleteProduct: di<DeleteProductUseCase>(),
    ),
  );
  di.registerFactory<DeliveryOrdersBloc>(
    () => DeliveryOrdersBloc(
      getNearbyOrders: di<GetNearbyOrdersUseCase>(),
      getOfferedOrders: di<GetOfferedOrdersUseCase>(),
      getCourierOrders: di<GetCourierOrdersUseCase>(),
      acceptOrder: di<AcceptOrderUseCase>(),
      updateDeliveryStatus: di<UpdateDeliveryStatusUseCase>(),
      cancelDeliveryOrder: di<CancelDeliveryOrderUseCase>(),
      pushCourierLocation: di<PushCourierLocationUseCase>(),
      setAvailability: di<SetAvailabilityUseCase>(),
      assignNearestCourier: di<AssignNearestCourierUseCase>(),
      locationService: di<LocationService>(),
    ),
  );
  di.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getProfile: di<GetProfileUseCase>(),
      updateProfile: di<UpdateProfileUseCase>(),
      getAddresses: di<GetAddressesUseCase>(),
    ),
  );
  di.registerFactory<AddressesBloc>(
    () => AddressesBloc(
      getAddresses: di<GetAddressesUseCase>(),
      saveAddress: di<SaveAddressUseCase>(),
      deleteAddress: di<DeleteAddressUseCase>(),
    ),
  );
}
