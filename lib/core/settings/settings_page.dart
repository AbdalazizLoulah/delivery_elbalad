import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/app_text.dart';
import '../settings/app_settings_cubit.dart';
import '../theme/app_colors.dart';
import '../widgets/app_widgets.dart';

/// إعدادات المظهر واللغة.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('الإعدادات')),
      body: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth > 720 ? 40.0 : 14.0;
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(title: 'المظهر'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _OptionTile(
                                  icon: Icons.light_mode_outlined,
                                  title: 'فاتح',
                                  selected: state.themeMode == ThemeMode.light,
                                  onTap: () => context
                                      .read<AppSettingsCubit>()
                                      .setThemeMode(ThemeMode.light),
                                ),
                                const Divider(height: 1),
                                _OptionTile(
                                  icon: Icons.dark_mode_outlined,
                                  title: 'غامق',
                                  selected: state.themeMode == ThemeMode.dark,
                                  onTap: () => context
                                      .read<AppSettingsCubit>()
                                      .setThemeMode(ThemeMode.dark),
                                ),
                                const Divider(height: 1),
                                _OptionTile(
                                  icon: Icons.settings_suggest_outlined,
                                  title: 'حسب النظام',
                                  selected: state.themeMode == ThemeMode.system,
                                  onTap: () => context
                                      .read<AppSettingsCubit>()
                                      .setThemeMode(ThemeMode.system),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SectionHeader(title: 'اللغة'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _OptionTile(
                                  icon: Icons.translate,
                                  title: 'العربية',
                                  subtitle: 'واجهة عربية بالكامل واتجاه من اليمين لليسار',
                                  selected: state.isArabic,
                                  onTap: () => context
                                      .read<AppSettingsCubit>()
                                      .setLocale(const Locale('ar')),
                                ),
                                const Divider(height: 1),
                                _OptionTile(
                                  icon: Icons.language,
                                  title: 'English',
                                  subtitle: 'Full English interface with left-to-right layout',
                                  selected: !state.isArabic,
                                  onTap: () => context
                                      .read<AppSettingsCubit>()
                                      .setLocale(const Locale('en')),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: AppText(
                                    'التغيير بيتم فورًا، واختيارك بيتحفظ علشان يفضل معاك في المرة الجاية.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: selected ? primary : AppColors.textHint),
      title: AppText(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? primary : null,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : AppText(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? primary : AppColors.textHint,
      ),
    );
  }
}
