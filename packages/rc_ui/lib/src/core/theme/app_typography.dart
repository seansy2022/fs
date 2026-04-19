import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';

class AppFonts {
  static const s9 = 9.0;
  static const s10 = 10.0;
  static const s11 = 11.0;
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s16 = 16.0;
  static const s18 = 18.0;
  static const s20 = 20.0;

  static const w200 = FontWeight.w200;
  static const w300 = FontWeight.w300;
  static const w400 = FontWeight.w400;
  static const w500 = FontWeight.w500;
  static const w600 = FontWeight.w600;
  static const w700 = FontWeight.w700;

  static const roboto = 'Roboto';
  static const pingFangSc = 'PingFang SC';
  static const notoSansSc = 'Noto Sans SC';

  /// 获取当前平台首选的基础字体（英文/数字）
  static String getFontFamily() => roboto;

  /// 获取当前平台的中文字体回退
  static List<String> getFontFallbacks() {
    // 简单判断平台（通常通过 Theme 或外部传入，
    // 这里由于是静态工具，如果需要实时判断可以使用 foundation.defaultTargetPlatform）
    return const [pingFangSc, notoSansSc];
  }

  static double compactFont(double value) =>
      (value * AppDimens.compactScale).clamp(10, value);
}

class AppTextStyles {
  // From original AppTextStyles
  static const caption = TextStyle(
    color: AppColors.outline,
    fontSize: AppFonts.s14,
  );
  static const captionStrong = TextStyle(
    color: AppColors.primary,
    fontSize: AppFonts.s14,
    fontWeight: AppFonts.w700,
  );
  static const matrixLabel = TextStyle(
    color: AppColors.outline,
    fontSize: AppFonts.s14,
    fontWeight: AppFonts.w700,
    letterSpacing: 2,
  );
  static const sectionLabel = TextStyle(
    color: AppColors.outline,
    fontSize: AppFonts.s11,
    letterSpacing: 1.2,
  );
  static const tinyLabel = TextStyle(
    color: AppColors.outline,
    fontSize: AppFonts.s14,
    letterSpacing: 0.5,
  );
  static const Color homeTopTextColor = Color(0xFF001024);

  static TextStyle homeTopName() {
    return TextStyle(
      color: homeTopTextColor,
      fontSize: AppFonts.s18,
      fontWeight: AppFonts.w700,
    );
  }

  static TextStyle homeTopStatus({required bool isConnected}) {
    return TextStyle(
      color: homeTopTextColor.withValues(alpha: isConnected ? 1 : 0.32),
      fontSize: AppFonts.s12,
    );
  }

  // From original AppPageTextStyles
  static const dashboardModelTag = TextStyle(
    color: AppColors.primary,
    fontSize: AppFonts.s10,
  );

  static const controlMappingHeader = TextStyle(
    color: Colors.white,
    fontSize: AppFonts.s16,
    fontWeight: FontWeight.w900,
  );

  static const controlMappingLabel = TextStyle(
    color: AppColors.text,
  );

  static const controlMappingValueBase = TextStyle(
    fontSize: AppFonts.s14,
  );

  static TextStyle controlMappingValue(Color color) {
    return controlMappingValueBase.copyWith(color: color);
  }

  static const mixingHint = TextStyle(
    color: AppColors.textDim,
    fontSize: AppFonts.s12,
    height: 1.5,
  );

  static const failsafeTitle = TextStyle(
    color: Colors.white,
    fontSize: AppFonts.s14,
  );

  static const failsafeStatus = TextStyle(
    color: Color(0xFF00C6FF),
    fontSize: AppFonts.s12,
  );
}
