import 'dart:ui';

import 'package:controller_app/src/core/localization/app_localizations.dart';
import 'package:controller_app/src/provider/app_locale_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('未保存偏好时跟随手机系统语言', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AppLocaleController();

    expect(
      controller.state,
      AppLanguage.fromLocale(PlatformDispatcher.instance.locale),
    );

    controller.dispose();
  });

  test('已保存的语言偏好优先于手机系统语言', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'controller_app.locale.v1': 'en',
    });
    final controller = AppLocaleController();

    await Future<void>.delayed(Duration.zero);

    expect(controller.state, AppLanguage.english);
    controller.dispose();
  });

  test('用户修改语言后会持久化选择', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AppLocaleController();

    await controller.setLanguage(AppLanguage.english);
    final preferences = await SharedPreferences.getInstance();

    expect(preferences.getString('controller_app.locale.v1'), 'en');
    controller.dispose();
  });
}
