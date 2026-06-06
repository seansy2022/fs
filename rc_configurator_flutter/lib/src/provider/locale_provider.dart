import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';
const _zhLocale = Locale('zh');
const _enLocale = Locale('en');

final initialLocaleProvider = Provider<Locale>((ref) => _enLocale);

Future<Locale> resolveInitialLocale({
  Locale? systemLocale,
  SharedPreferences? prefs,
}) async {
  final localPrefs = prefs ?? await SharedPreferences.getInstance();
  final savedLocale = _parseSavedLocale(localPrefs.getString(_localeKey));
  if (savedLocale != null) return savedLocale;
  final locale = normalizeLocale(systemLocale);
  await localPrefs.setString(_localeKey, locale.toLanguageTag());
  return locale;
}

Locale normalizeLocale(Locale? locale) {
  if (locale?.languageCode == 'zh') return _zhLocale;
  return _enLocale;
}

Locale? _parseSavedLocale(String? value) {
  if (value == null || value.isEmpty) return null;
  final code = value.split(RegExp('[-_]')).first;
  return normalizeLocale(Locale(code));
}

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return ref.watch(initialLocaleProvider);
  }

  Future<void> setLocale(Locale locale) async {
    state = normalizeLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, state.toLanguageTag());
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
