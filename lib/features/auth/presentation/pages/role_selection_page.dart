import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_user.dart';
import '../widgets/auth_widgets.dart';

import '../../../../core/localization/app_text.dart';
/// اختيار نوع الحساب: مشتري / بائع / ديليفاري.
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const SizedBox(height: 10),
              const Center(child: AppLogo(size: 88, showName: true)),
              const SizedBox(height: 22),
              const AppText(
                'اختار نوع حسابك وابدأ حالًا',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 22),
              for (final role in UserRole.values) ...[
                RoleCard(
                  role: role,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.register,
                    arguments: role,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppText('عندك حساب بالفعل؟',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                    child: const AppText('تسجيل الدخول'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const DemoCredentialsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
