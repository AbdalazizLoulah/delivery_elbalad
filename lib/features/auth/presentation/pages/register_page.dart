import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_bloc.dart';
import '../utils/role_ui.dart';

import '../../../../core/localization/app_text.dart';
/// إنشاء حساب جديد (الدور بيتم اختياره قبل كده).
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.role});

  final UserRole? role;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeAddressController = TextEditingController();
  late UserRole _role = widget.role ?? UserRole.buyer;
  CountryInfo _country = Countries.egypt;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthSignUpRequested(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: Countries.normalizePhone(_phoneController.text, fallback: _country),
          role: _role,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('حساب جديد')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => current.errorMessage != null && previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.danger, content: AppText(state.errorMessage ?? '')),
          );
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const AppText('نوع الحساب',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final role in UserRole.values)
                        ChoiceChip(
                          label: AppText(role.label),
                          selected: _role == role,
                          avatar: Icon(role.icon, size: 16),
                          onSelected: (_) => setState(() => _role = role),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _nameController,
                    label: _role == UserRole.seller ? 'اسم المتجر' : 'الاسم بالكامل',
                    icon: Icons.person_outline,
                    validator: (value) => Validators.required(value, message: 'اكتب الاسم'),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  AppPhoneField(
                    controller: _phoneController,
                    country: _country,
                    onCountryChanged: (country) => setState(() => _country = country),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _passwordController,
                    label: 'كلمة السر',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  if (_role != UserRole.buyer) ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _storeAddressController,
                      label: _role == UserRole.seller ? 'عنوان المتجر' : 'منطقة العمل',
                      hint: 'اكتب العنوان بالتفصيل',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'إنشاء الحساب',
                    icon: Icons.person_add_alt,
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const AppText('عندك حساب؟ سجل دخول'),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    _role == UserRole.seller
                        ? 'هتقدر تحدد موقع المتجر من الملف الشخصي بعد التسجيل لتظهر لك الطلبات القريبة.'
                        : _role == UserRole.courier
                            ? 'هتقدر تفعّل حالة "متاح" من لوحة الطلبات علشان توصلك الطلبات الأقرب ليك.'
                            : 'هتقدر تضيف عناوينك على الخريطة وتتابع طلباتك لحظة بلحظة.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.roles),
                    child: const AppText('رجوع لاختيار نوع حساب تاني'),
                  ),
                      ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
