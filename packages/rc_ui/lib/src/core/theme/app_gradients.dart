import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  /// 主色蓝色渐变（用于进度条填充、激活态等）
  static const primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.primaryBright],
  );

  /// 反向蓝色渐变
  static const primaryReverse = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.primary, AppColors.primaryBright],
  );

  /// 垂直方向的主色渐变
  static const primaryVertical = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [AppColors.primary, AppColors.primaryBright],
  );

  /// 垂直方向的反向渐变
  static const primaryVerticalReverse = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primary, AppColors.primaryBright],
  );

  /// 按钮下压时的半透明蓝色渐变
  static const pressed = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0000C6FF), Color(0x8000C6FF)],
  );

  /// 面板/卡片的激活态背景渐变
  static const activeSurface = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFF00C6FF), Color(0x0000C6FF)],
  );

  /// 仪表盘卡片/菜单项的纵向边框渐变
  static const metricBorder = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0x667DA2CE),
      Color(0xA37DA2CE),
      Color(0xFF7DA2CE),
      Color(0xA37DA2CE),
      Color(0x667DA2CE),
    ],
    stops: [0, 0.2807, 0.5394, 0.7815, 1],
  );

  /// 13渐变: #00C6FF 100% - #0072FF 100% (垂直)
  static const v13 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
  );

  /// 16渐变: #00C6FF 8% - #00C6FF 100% (垂直)
  static const v16 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x1400C6FF), // 8% opacity of #00C6FF
      Color(0xFF00C6FF),
    ],
  );

  /// 20渐变: #0072ff 0% - #0072ff 48% (垂直)
  static const v20 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x000072FF), // 0% opacity
      Color(0x7A0072FF),
    ],
  );

  /// 21渐变: 00c6ff 0% - 0072ff 100% (垂直)
  static const v21 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x0000C6FF), // 0% opacity
      Color(0x7A00C6FF),
    ],
  );

  /// 24渐变: rgba(0,114,255,0.16) -> rgba(0,114,255,0.16) (垂直)
  static const v24 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x290072FF), Color(0x290072FF)],
  );

  /// 表面消隐渐变: rgba(27, 45, 77, 1) 0% - rgba(27, 45, 77, 0) 100% (垂直)
  static const surfaceFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B2D4D), Color(0x001B2D4D)],
  );

  /// 按钮选中态顶部的混合扫光渐变:
  /// 顶部是 rgba(0, 198, 255, 0.5) 混合在 rgba(27, 45, 77, 0.4) 上的视觉效果
  /// 底部是 rgba(27, 45, 77, 0.4) 的原始色值
  static const selectionTopLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x0000C6FF), // 顶部混合后的预测值
      Color(0x7F00C6FF), // 底部原始背景色 (rgba(27, 45, 77, 0.4))
    ],
  );
}
