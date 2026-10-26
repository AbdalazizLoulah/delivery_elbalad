import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/address.dart';
import '../bloc/addresses_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// إدارة عناوين المستخدم.
class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    return BlocProvider(
      create: (_) => di<AddressesBloc>()..add(AddressesStarted(user.id)),
      child: _AddressesView(userId: user.id),
    );
  }
}

class _AddressesView extends StatelessWidget {
  const _AddressesView({required this.userId});

  final String userId;

  Future<void> _addNew(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed<PickedAddress>(
      AppRoutes.addressPicker,
    );
    if (result == null || !context.mounted) return;
    context.read<AddressesBloc>().add(AddressSaved(Address(
          id: 'a-${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          label: result.label,
          details: result.details,
          lat: result.lat,
          lng: result.lng,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('عناويني')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNew(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const AppText('عنوان جديد'),
      ),
      body: BlocConsumer<AddressesBloc, AddressesState>(
        listenWhen: (previous, current) =>
            (current.savedAddress != null && previous.savedAddress != current.savedAddress) ||
            (current.errorMessage != null && previous.errorMessage != current.errorMessage),
        listener: (context, state) {
          if (state.errorMessage != null) {
            showAppSnackBar(context, state.errorMessage!, isError: true);
          }
          if (state.savedAddress != null) {
            showAppSnackBar(context, 'تم حفظ العنوان ✅', isSuccess: true);
          }
        },
        builder: (context, state) {
          if (state.isLoading) return const LoadingView();
          if (state.addresses.isEmpty) {
            return const EmptyView(
              title: 'مفيش عناوين محفوظة',
              subtitle: 'ضيف عنوان من الخريطة علشان تعرف توصل طلباتك بسرعة',
              icon: Icons.location_off_outlined,
            );
          }

          return Responsive.centerContent(ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: state.addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final address = state.addresses[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        AppText(address.label,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        if (address.isDefault)
                          const Chip(
                            label: AppText('الافتراضي'),
                            visualDensity: VisualDensity.compact,
                          ),
                        const Spacer(),
                        IconButton(
                          tooltip: trOf(context, 'حذف'),
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.danger),
                          onPressed: () => context
                              .read<AddressesBloc>()
                              .add(AddressDeleted(address.id)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppText(address.details,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    AppText(
                      '${address.lat.toStringAsFixed(4)}, ${address.lng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textHint),
                    ),
                    if (!address.isDefault) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => context
                            .read<AddressesBloc>()
                            .add(AddressSaved(address.copyWith(isDefault: true))),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const AppText('اجعله الافتراضي'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ));
        },
      ),
    );
  }
}
