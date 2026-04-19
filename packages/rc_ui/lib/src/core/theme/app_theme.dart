import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_dimens.dart';
export 'app_typography.dart';
export 'app_gradients.dart';
export 'app_decorations.dart';

ThemeData appTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: AppFonts.roboto,
    fontFamilyFallback: defaultTargetPlatform == TargetPlatform.iOS
        ? const [AppFonts.pingFangSc, AppFonts.notoSansSc]
        : const [AppFonts.notoSansSc, AppFonts.pingFangSc],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text),
      bodySmall: TextStyle(color: AppColors.textDim),
      titleMedium: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );
}
