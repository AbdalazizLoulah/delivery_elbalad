import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/utils/responsive.dart';
/// تعديل بيانات الملف الشخصي (وتحديد موقع المتجر للبائع).
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    return BlocProvider(
      create: (_) => di<ProfileBloc>()..add(ProfileStarted(user)),
      child: _ProfileEditView(initial: user),
    );
  }
}

class _ProfileEditView extends StatefulWidget {
  const _ProfileEditView({required this.initial});

  final AppUser initial;

  @override
  State<_ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<_ProfileEditView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.initial.fullName);
  late final TextEditingController _phone = TextEditingController(text: widget.initial.phone);
  late final TextEditingController _address =
      TextEditingController(text: widget.initial.addressText ?? '');
  late CountryInfo _country =
      Countries.fromPhone(widget.initial.phone) ?? Countries.egypt;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _lat = widget.initial.lat;
    _lng = widget.initial.lng;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickStoreLocation() async {
    final result = await Navigator.of(context).pushNamed<PickedAddress>(
      AppRoutes.addressPicker,
      arguments: AddressPickerArgs(
        initialPoint: _lat == null || _lng == null ? null : LatLngLike(_lat!, _lng!),
        initialDetails: _address.text,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      _address.text = result.details;
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = widget.initial;
    context.read<ProfileBloc>().add(ProfileSaved(
          user.copyWith(
            fullName: _name.text.trim(),
            phone: Countries.normalizePhone(_phone.text, fallback: _country),
            addressText: _address.text.trim(),
            lat: _lat,
            lng: _lng,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.initial.role;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          (current.saved && !previous.saved) ||
          (current.errorMessage != null && previous.errorMessage != current.errorMessage),
      listener: (context, state) {
        if (state.errorMessage != null) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
        if (state.saved) {
          showAppSnackBar(context, 'تم تحديث البيانات ✅', isSuccess: true);
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const AppText('تعديل البيانات')),
          body: Form(
            key: _formKey,
            child: Responsive.centerContent(ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppTextField(
                  controller: _name,
                  label: role == UserRole.seller ? 'اسم المتجر' : 'الاسم بالكامل',
                  icon: Icons.person_outline,
                  validator: (value) => Validators.required(value, message: 'اكتب الاسم'),
                ),
                const SizedBox(height: 14),
                AppPhoneField(
                  controller: _phone,
                  country: _country,
                  onCountryChanged: (country) => setState(() => _country = country),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _address,
                  label: role == UserRole.seller ? 'عنوان المتجر' : 'العنوان',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText('الموقع على الخريطة',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      AppText(
                        _lat == null
                            ? 'لسه محددتش موقعك. تحديد الموقع مهم لحساب مصاريف الدليفاري.'
                            : 'الموقع: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      AppPrimaryButton(
                        outlined: true,
                        label: 'تحديد الموقع على Google Maps',
                        icon: Icons.map_outlined,
                        onPressed: _pickStoreLocation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: 'حفظ التعديلات',
                  icon: Icons.save_outlined,
                  isLoading: state.isSaving,
                  onPressed: _save,
                ),
              ],
            )),
          ),
        );
      },
    );
  }
}
