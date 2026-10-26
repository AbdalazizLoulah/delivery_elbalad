import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_localization.dart';

/// إعدادات التطبيق المحفوظة: المظهر واللغة.
class AppSettingsState extends Equatable {
  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar'),
  });

  final ThemeMode themeMode;
  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  AppSettingsState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale.languageCode];
}

/// بيتحكم في المظهر واللغة ويحفظ الاختيار بين جلسات التطبيق.
class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._preferences) : super(_read(_preferences));

  static const String _themeKey = 'app_theme_mode';
  static const String _localeKey = 'app_locale';

  final SharedPreferences _preferences;

  static AppSettingsState _read(SharedPreferences preferences) {
    final themeName = preferences.getString(_themeKey);
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => ThemeMode.system,
    );
    final languageCode = preferences.getString(_localeKey) == 'en' ? 'en' : 'ar';
    final locale = Locale(languageCode);

    // بنحدّث الحالة العامة قبل أول بناء للواجهة علشان الـ formatters
    // (الأرقام والتواريخ) تبقى بنفس اللغة من أول لحظة.
    AppLocale.current = locale;

    return AppSettingsState(themeMode: themeMode, locale: locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    emit(state.copyWith(themeMode: mode));
    await _preferences.setString(_themeKey, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'en' ? 'en' : 'ar';
    if (state.locale.languageCode == code) return;
    AppLocale.current = Locale(code);
    emit(state.copyWith(locale: Locale(code)));
    await _preferences.setString(_localeKey, code);
  }
}
