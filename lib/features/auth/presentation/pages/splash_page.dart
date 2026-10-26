import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/splash_view.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthStarted());
    });
  }

  void _redirect(AuthState state) {
    if (_redirected || state.isBusy) return;

    final UserRole? role = state.user?.role;

    final destination = state.isAuthenticated && role != null
        ? AppRoutes.homeForRole(role)
        : AppRoutes.roles;

    _redirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _redirect(state),
      child: Builder(
        builder: (context) {
          final state = context.watch<AuthBloc>().state;

          if (!state.isBusy) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _redirect(state);
            });
          }

          return const SplashView();
        },
      ),
    );
  }
}
