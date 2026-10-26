import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/app_localization.dart';
import '../localization/app_text.dart';
import '../utils/countries.dart';
import '../utils/validators.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;
    final onButton =
        ThemeData.estimateBrightnessForColor(buttonColor) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: onButton),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: outlined ? null : onButton),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: AppText(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: AppText(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: color == null
          ? null
          : FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: onButton,
              disabledBackgroundColor: color?.withValues(alpha: 0.5),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
      child: child,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int maxLines;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      // رسائل التحقق بتيجي بالعربي، فنترجمها هنا قبل ما تظهر.
      validator: validator == null
          ? null
          : (value) {
              final error = validator!(value);
              if (error == null) return null;
              return tr(error, locale: locale);
            },
      maxLines: maxLines,
      onChanged: onChanged,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label == null ? null : tr(label!, locale: locale),
        hintText: hint == null ? null : tr(hint!, locale: locale),
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        suffixIcon: suffix,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

/// اختيار بلد رقم الموبايل (بيعتمد عليه تحديد عدد الأرقام المسموح).
class AppCountryDropdown extends StatelessWidget {
  const AppCountryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CountryInfo value;
  final ValueChanged<CountryInfo> onChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: tr('الدولة', locale: locale),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CountryInfo>(
          value: value,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 360,
          items: [
            for (final country in Countries.all)
              DropdownMenuItem<CountryInfo>(
                value: country,
                child: Text(
                  country.label(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
          onChanged: (country) {
            if (country != null) onChanged(country);
          },
        ),
      ),
    );
  }
}

/// حقل موبايل كامل: اختيار البلد + الرقم بعدد الأرقام المسموح للبلد.
///
/// على الشاشات الضيقة بنحط اختيار البلد فوق الرقم بدل ما نضغط الحقلين
/// جنب بعض (الرقم بيفضل واضح وقابل للكتابة).
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
  });

  final TextEditingController controller;
  final CountryInfo country;
  final ValueChanged<CountryInfo> onCountryChanged;

  @override
  Widget build(BuildContext context) {
    final countryField = AppCountryDropdown(
      value: country,
      onChanged: onCountryChanged,
    );
    final phoneField = AppTextField(
      controller: controller,
      label: 'رقم الموبايل',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      inputFormatters: [PhoneNumberInputFormatter(country: country)],
      validator: (value) => Validators.phone(value, country: country),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 340) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 132, child: countryField),
              const SizedBox(width: 10),
              Expanded(child: phoneField),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            countryField,
            const SizedBox(height: 10),
            phoneField,
          ],
        );
      },
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = theme.dividerTheme.color ?? theme.colorScheme.outlineVariant;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AppText(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: AppText(actionLabel!)),
        ],
      ),
    );
  }
}
