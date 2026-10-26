import 'package:delivery_elbalad/features/auth/domain/entities/app_user.dart';
import 'package:delivery_elbalad/features/auth/presentation/utils/role_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_text.dart';
class DemoLogins extends StatelessWidget {
  const DemoLogins({super.key, required this.onPick});

  final void Function(String email) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('دخول سريع للتجربة',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final role in UserRole.values)
                ActionChip(
                  label: AppText(role.label),
                  avatar: Icon(role.icon, size: 16, color: role.color),
                  onPressed: () => onPick(_demoEmail(role)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _demoEmail(UserRole role) => switch (role) {
        UserRole.buyer => 'buyer@elbalad.app',
        UserRole.seller => 'seller@elbalad.app',
        UserRole.courier => 'courier@elbalad.app',
      };
}
