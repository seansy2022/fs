import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rc_ui/src/core/theme/app_theme.dart';

class RCText extends StatelessWidget {
  const RCText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    
    // 注入全局字体配置
    final effectiveStyle = (style ?? defaultStyle).copyWith(
      fontFamily: AppFonts.roboto, // 全平台英文/数字使用 Roboto
      fontFamilyFallback: defaultTargetPlatform == TargetPlatform.iOS
          ? const [AppFonts.pingFangSc, AppFonts.notoSansSc]
          : const [AppFonts.notoSansSc, AppFonts.pingFangSc],
    );

    return Text(
      data,
      style: effectiveStyle,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
