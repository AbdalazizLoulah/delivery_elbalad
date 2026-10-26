import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_user.dart';
import '../utils/role_ui.dart';

import '../../../../core/localization/app_text.dart';
/// لوجو التطبيق.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.showName = false});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.delivery_dining, size: size * 0.55, color: Colors.white),
        ),
        if (showName) ...[
          const SizedBox(height: 12),
          const AppText(
            AppConfig.appName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}

/// كارت اختيار الدور.
class RoleCard extends StatelessWidget {
  const RoleCard({super.key, required this.role, required this.onTap});

  final UserRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(role.icon, color: role.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      role.label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      role.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة بيانات تجريبية (بتظهر في الوضع التجريبي فقط).
class DemoCredentialsCard extends StatelessWidget {
  const DemoCredentialsCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isDemoMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              const Expanded(
                child: AppText('حسابات للتجربة (كلمة السر: 123456)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AppText('مشتري: buyer@elbalad.app', style: TextStyle(fontSize: 12.5)),
          const AppText('بائع: seller@elbalad.app', style: TextStyle(fontSize: 12.5)),
          const AppText('ديليفاري: courier@elbalad.app', style: TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// شارة صغيرة توضح دور المستخدم.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 14, color: role.color),
          const SizedBox(width: 4),
          AppText(
            role.label,
            style: TextStyle(color: role.color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// شاشة تحميل موحدة.
class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0x33000000),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
