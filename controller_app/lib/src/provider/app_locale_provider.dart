import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_localizations.dart';

/// 管理语言偏好：无用户设置时跟随手机系统语言。
class AppLocaleController extends StateNotifier<AppLanguage> {
  AppLocaleController() : super(_systemLanguage()) {
    AppText.setLanguage(state);
    _restoreUserPreference();
  }

  static const _storageKey = 'controller_app.locale.v1';
  bool _hasUserSelection = false;

  /// 保存用户主动选择的语言，并立即驱动界面刷新。
  Future<void> setLanguage(AppLanguage language) async {
    _hasUserSelection = true;
    if (state != language) {
      state = language;
    }
    AppText.setLanguage(language);
    await _saveUserPreference(language);
  }

  static AppLanguage _systemLanguage() {
    return AppLanguage.fromLocale(PlatformDispatcher.instance.locale);
  }

  Future<void> _restoreUserPreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (_hasUserSelection) {
      return;
    }
    final storedCode = preferences.getString(_storageKey);
    if (storedCode == null) {
      return;
    }
    switch (storedCode) {
      case 'zh':
        state = AppLanguage.chinese;
        AppText.setLanguage(state);
        break;
      case 'en':
        state = AppLanguage.english;
        AppText.setLanguage(state);
        break;
    }
  }

  Future<void> _saveUserPreference(AppLanguage language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, language.locale.languageCode);
  }
}

final appLocaleProvider =
    StateNotifierProvider<AppLocaleController, AppLanguage>(
      (ref) => AppLocaleController(),
    );
