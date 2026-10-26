import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/localization/app_localization.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/settings/app_settings_cubit.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/splash_view.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_cubit.dart';
import 'features/notifications/presentation/widgets/order_notification_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final preferencesFuture = SharedPreferences.getInstance();
      try {
        await initializeDateFormatting();
      } catch (_) {}

      final preferences = await preferencesFuture;
      if (di.isRegistered<SharedPreferences>()) {
        await di.reset();
      }
      await configureDependencies(preferences);

      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // إعادة محاولة صامتة بدون أي UI — المستخدم مش شايف غير اللودر.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) await _initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const DeliveryElBaladApp();

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      color: AppColors.primary,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashView(),
      builder: (context, child) => _GreenBackground(child: child),
    );
  }
}

/// أي فراغ/لحظة انتقال بتبقى خضراء — مش سوداء.
class _GreenBackground extends StatelessWidget {
  const _GreenBackground({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : AppColors.primary,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class DeliveryElBaladApp extends StatelessWidget {
  const DeliveryElBaladApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppSettingsCubit>.value(
      value: di<AppSettingsCubit>(),
      child: BlocProvider<AuthBloc>(
        create: (_) => di<AuthBloc>(),
        child: const _SessionScope(),
      ),
    );
  }
}

class _SessionScope extends StatelessWidget {
  const _SessionScope();

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthBloc, String>((bloc) => bloc.state.user?.id ?? '');

    return MultiBlocProvider(
      key: ValueKey(userId),
      providers: [
        BlocProvider<CartBloc>(
          create: (_) => di<CartBloc>()..add(CartStarted(userId)),
        ),
        BlocProvider<FavoritesBloc>(
          create: (_) => di<FavoritesBloc>()..add(FavoritesStarted(userId)),
        ),
        BlocProvider<NotificationsCubit>.value(value: di<NotificationsCubit>()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsCubit>().state;
    return MaterialApp(
      title: tr(AppConfig.appName, locale: settings.locale),
      debugShowCheckedModeBanner: false,
      color: AppColors.primary,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) => _GreenBackground(
        child: OrderNotificationWatcher(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
