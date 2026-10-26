import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/demo_logins.dart';

import '../../../../core/localization/app_text.dart';
/// تسجيل الدخول (نفس الشاشة لكل الأدوار - الدور بيجي من الحساب).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.role});

  final UserRole? role;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthSignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  void _fillDemo(String email) {
    _emailController.text = email;
    _passwordController.text = '123456';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('تسجيل الدخول')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage && current.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: AppText(state.errorMessage ?? ''),
            ),
          );
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      const Center(child: AppLogo(size: 76)),
                      const SizedBox(height: 18),
                      if (widget.role != null)
                        Center(child: RoleBadge(role: widget.role!))
                      else
                        const Center(
                          child: AppText('سجل دخولك بأي دور',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      const SizedBox(height: 22),
                      AppTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'name@example.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _passwordController,
                        label: 'كلمة السر',
                        icon: Icons.lock_outline,
                        obscureText: _obscure,
                        validator: Validators.password,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 22),
                      AppPrimaryButton(
                        label: 'دخول',
                        icon: Icons.login,
                        isLoading: state.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.register,
                          arguments: widget.role,
                        ),
                        child: const AppText('معندكش حساب؟ اعمل حساب جديد'),
                      ),
                      const SizedBox(height: 14),
                      DemoLogins(onPick: _fillDemo),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (state.isLoading) const Positioned.fill(child: AuthLoadingOverlay()),
            ],
          );
        },
      ),
    );
  }
}
