import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 应用支持的界面语言。
enum AppLanguage {
  chinese(Locale('zh')),
  english(Locale('en'));

  const AppLanguage(this.locale);

  final Locale locale;

  static AppLanguage fromLocale(Locale locale) {
    return locale.languageCode.toLowerCase() == 'zh'
        ? AppLanguage.chinese
        : AppLanguage.english;
  }
}

/// 集中维护中英文界面文案；中文为默认回退文案。
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = <Locale>[Locale('zh'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// 根据当前语言返回对应译文；未迁移的中文文案安全回退为原文。
  String text(String source) {
    if (locale.languageCode == 'zh') {
      return source;
    }
    return _englishText[source] ?? source;
  }
}

/// 供非 BuildContext 场景与批量迁移的静态界面文案读取入口。
class AppText {
  AppText._();

  static AppLanguage _language = AppLanguage.fromLocale(
    PlatformDispatcher.instance.locale,
  );

  /// 同步当前语言，供应用根节点重建期间读取。
  static void setLanguage(AppLanguage language) {
    _language = language;
  }

  /// 返回当前语言的界面文案；中文及未配置项保留原文。
  static String tr(String source) {
    return _language == AppLanguage.chinese
        ? source
        : _englishText[source] ?? source;
  }
}

/// 为界面层提供简洁的文案读取方式。
extension AppLocalizationBuildContext on BuildContext {
  String tr(String source) => AppLocalizations.of(this).text(source);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _englishText = <String, String>{
  "English": "English",
  "all": "all",
  "中位": "Center",
  "低": "Low",
  "低于": "Below",
  "低速": "Low Speed",
  "体感控制": "Motion Control",
  "体感控制行程校准": "Motion Calibration",
  "体感校准：可通过此功能，校准最大通道行程对应的陀螺仪角度":
      "Motion Calibration:Calibrate gyro angle for max channel travel.",
  "保存失败": "Save failed.",
  "保存成功": "Save successful.",
  "保持": "Hold",
  "信号低！": "Signal Low",
  "信号强度": "Signal",
  "值": "Value",
  "停止/怠速对应角度:": "Stop/Idle Angle:",
  "关": "OFF",
  "其他": "Other",
  "刷新": "Refresh",
  "前": "Forward",
  "前进比例": "Forward Rate",
  "单边右手": "Right Only",
  "单边左手": "Left Only",
  "去配对": "Pair",
  "双手": "Both Hands",
  "反向": "REV",
  "右": "Right",
  "右手": "Right Hand",
  "右手油门": "Left-hand Throttle",
  "右手油门表示右边区域控制油门\n左边油门表示左边区域控制油门\n右手油门：右边区域控制油门\n左边油门：左边区域控制油门":
      "Right-hand Throttle means the right stick controls throttle.\nLeft-hand Throttle means the left stick controls throttle.\nRight-hand Throttle: the right stick controls throttle.\nLeft-hand Throttle: the left stick controls throttle.",
  "名称": "Name",
  "后": "Back",
  "后退比例": "Reverse Rate",
  "固件升级": "Firmware Update",
  "固定位置": "Fixed Position",
  "固定位置表示可以固定起点开始行程\n隐藏可变位置表示可以任意起点开始行程":
      "Fixed position: fixed start point.\nVariable position: any start point.",
  "固定值": "Fixed Value",
  "基本设置": "Basic Settings",
  "复位/保存": "Reset/Save",
  "多状态": "Multi-State",
  "失控保护": "Fail-safe",
  "富斯智能车控": "Flysky SmartDrive",
  "对应角度已被修改，是否保存": "The angle has been modified. Save changes?",
  "履带混控": "Track",
  "左": "Left",
  "左手": "Left Hand",
  "左手油门": "Right-hand Throttle",
  "已连接": "Connected",
  "已配对列表": "Paired list",
  "已配对设备列表": "Paired list",
  "帮助": "Help",
  "开": "ON",
  "开关": "Switch",
  "开启手机蓝牙\n是\n否": "Enable Bluetooth\nYes / No",
  "开始": "Start",
  "当前陀螺仪实时角度参考值：": "Gyro Angle (Live):",
  "手型设置": "Stick Mode",
  "报警和提示": "Alerts",
  "报警提示": "Alert Prompt",
  "报警电量": "Alert Battery",
  "挡位设置": "Gear Settings",
  "控制类型": "Control Type",
  "搜索到已连接的xxx接收机在线，确定连接使用吗？\n不再提示\n是":
      "Detected connected receiver \"xxx\" online. Connect?\nDon't ask again / Yes",
  "操作会导致失控，请确认安全！\n接收机退出蓝牙模式后需要重启接收机才能再次连上，确认吗？":
      "This will cause loss of control. \nAfter RX exits Bluetooth mode, it must restart to reconnect. Confirm?",
  "操作会导致失控，请确认安全！\n此设备正在使用，确定删除吗？":
      "This will cause loss of control. Confirm safety!\nDevice in use. Delete anyway?",
  "操作会导致失控，请确认安全！\n确定断开当前设备，连接新设备吗？":
      "This will cause loss of control!Confirm safety. Disconnect current and connect new?",
  "操控模式": "Control Mode",
  "新增": "Add",
  "方向": "Steering",
  "方向居中对应角度：": "Center Angle:",
  "方向校准": "Steering Calibration",
  "无配对设备": "No Paired Device",
  "是否确认删除设备": "Confirm to delete device?",
  "暂无历史设备": "No paired device",
  "暂无可用蓝牙设备": "No available Bluetooth devices",
  "更新失败，请检查设备状态后再试\n知道了": "Update failed. Check device status and retry.",
  "最低电压": "Min Voltage",
  "最大前进速度对应角度：": "Max Forward Angle:",
  "最大右转方向对应角度：": "Max Right Angle:",
  "最大后退速度对应角度：": "Max Reverse Angle:",
  "最大左转方向对应角度：": "Max Left Angle:",
  "未连接": "Disconnected",
  "查找新设备": "Find New Device",
  "根据右图示意和实时旋转角度参考，请前后转动手机选择适合自己的控制角度，并输入对应控制角度完成自定义控制校准。":
      "See diagram & live gyro. Tilt phone forward/backward to set angle, then enter value to calibrate.",
  "根据右图示意和实时旋转角度参考，请左右转动手机选择适合自己的控制角度，并输入对应控制角度完成自定义控制校准。":
      "See diagram & live gyro. Tilt phone left/right to set angle, then enter value to calibrate.",
  "模型低信号报警": "Low Signal Alert",
  "模型低电压报警": "Low Voltage Alert",
  "模型断开/连上提示": "disconnected/connected prompt",
  "正在使用": "Active",
  "正在连接": "Connecting...",
  "正在配对，请确认接收机处于蓝牙模式（LED灯常亮2秒灭一秒）":
      "Pairing... Make sure RX is in Bluetooth mode (LED on for 2s, off for 1s).",
  "油门": "Throttle",
  "油门校准": "Throttle Calibration",
  "满电电压": "Max Voltage",
  "版本已是最新，确定重刷固件？": "Version is already latest. Re-flash firmware?",
  "状态1": "State 1",
  "状态1-5": "State 1-5",
  "电压": "RX Voltage",
  "电量低！": "Power Low",
  "电量转换": "Battery Conversion",
  "确定放弃当前连接接收机去配对其它接收机\n否\n是":
      "Disconnect current receiver and pair with another?\nYes / No",
  "确定更新为旧版？": "Downgrade to an older version?",
  "禁用": "Disable",
  "简体中文": "Simplified Chinese",
  "网络异常": "Network Error",
  "背景音乐设置": "Background Music",
  "自定义控制校准": "Custom Calibration",
  "设置": "Settings",
  "设置接收机退出蓝牙模式": "Set RX to exit Bluetooth mode",
  "语言": "Language",
  "语音": "Voice",
  "说明书": "Manual",
  "请连接接收机再操作\n知道了": "Please connect the RX first.\nOK",
  "辅助1": "AUX1",
  "辅助2": "AUX2",
  "连接失败，请检查设备状态后再试\n知道了":
      "Connection failed. Check device status and retry\nOK",
  "连接成功": "Connected successfully",
  "选择本地音乐": "Select Local Music",
  "选择语言": "Select Language",
  "通道设置": "Channels",
  "配对成功": "Pairing successful!",
  "配对接收机": "Pair RX",
  "隐藏可变位置": "Variable Position",
  "震动": "Vibration",
  "高": "High",
  "高速": "High Speed",
  "默认背景音乐": "Default Background Music",
  // 第二批页面与全局提示文案。
  "连接失败": "Connection Failed",
  "断开失败": "Disconnection Failed",
  "提示": "Notice",
  "确定": "Confirm",
  "取消": "Cancel",
  "知道了": "OK",
  "正在重连": "Reconnecting",
  "蓝牙设备": "Bluetooth Device",
  "蓝牙当前不可用，请稍后重试。":
      "Bluetooth is currently unavailable. Please try again later.",
  "连接设备失败，请重试。": "Failed to connect to the device. Please try again.",
  "断开连接失败，请重试。": "Failed to disconnect. Please try again.",
  "扫描停止失败，请稍后重试。": "Failed to stop scanning. Please try again later.",
  "蓝牙扫描初始化失败，请稍后重试。":
      "Failed to initialize Bluetooth scanning. Please try again later.",
  "扫描启动失败，请稍后重试。": "Failed to start scanning. Please try again later.",
  "当前连接接收机断开失败，请重试。":
      "Failed to disconnect the current receiver. Please try again.",
  "确定放弃当前连接接收机去配对其它接收机？":
      "Disconnect the current receiver and pair another one?",
  "辅助通道": "AUX Channel",
  "声音开": "Sound ON",
  "声音关": "Sound OFF",
  "陀螺仪开": "Gyro ON",
  "陀螺仪关": "Gyro OFF",
  "微调开": "Trim ON",
  "微调关": "Trim OFF",
  "警示灯开": "Hazard Lights ON",
  "警示灯关": "Hazard Lights OFF",
  "四方向控制": "Four-way Control",
  "帮助中心": "Help Center",
  "退出蓝牙模式": "Exit Bluetooth Mode",
  "当前未连接接收机，无需退出蓝牙模式。":
      "No receiver is connected. No need to exit Bluetooth mode.",
  "确定退出蓝牙模式？\n退出后需要重新连接才能控制。":
      "Exit Bluetooth mode? Reconnect the receiver before controlling it again.",
  "已退出": "Exited",
  "接收机已退出蓝牙模式。": "The receiver has exited Bluetooth mode.",
  "操作失败": "Operation Failed",
  "退出蓝牙模式失败，请重试。": "Failed to exit Bluetooth mode. Please try again.",
  "是": "Yes",
  "否": "No",
  "默认": "Default",
  "文件选择不可用": "File Selection Unavailable",
  "当前环境未注册文件选择插件，请重启应用后重试。":
      "File selection is unavailable. Restart the app and try again.",
  "选择失败": "Selection Failed",
  "打开本地文件失败，请重试。": "Failed to open the local file. Please try again.",
  "格式不支持": "Unsupported Format",
  "仅支持 MP3 或 WAV 音频文件。": "Only MP3 and WAV audio files are supported.",
  "当前固件版本：": "Current Firmware Version:",
  "最新固件版本：": "Latest Firmware Version:",
  "将下载最新固件包并开始升级。升级过程中请勿断开连接。":
      "The latest firmware will be downloaded and installed. Do not disconnect during the update.",
  "无法升级": "Unable to Update",
  "请先连接接收机，并确认固件包可用。":
      "Connect the receiver first and ensure the firmware package is available.",
  "下载固件中": "Downloading Firmware",
  "升级中": "Updating",
  "升级版本": "Update Firmware",
  "请检查设备状态后再试！": "Check the device status and try again.",
  "升级连接已结束，请检查设备状态后重试！":
      "The update connection has ended. Check the device and try again.",
  "升级超时，请检查设备连接后重试！":
      "Update timed out. Check the device connection and try again.",
  "报警信号值": "Signal Threshold",
  "选择电池类型": "Select Battery Type",
  "方向(CH1)": "Steering (CH1)",
  "油门(CH2)": "Throttle (CH2)",
  "同步失败": "Sync Failed",
  "通道已设为禁用，但失控保护参数未能同步到接收机，请检查蓝牙连接后重试。":
      "The channel was disabled, but its fail-safe setting could not be synced to the receiver. Check Bluetooth and try again.",
  "修改状态名称": "Edit State Name",
  "大灯": "Headlights",
  "刹车灯": "Brake Lights",
  "倒车灯": "Reverse Lights",
  "左转灯": "Left Turn Signal",
  "右转灯": "Right Turn Signal",
  "挡位控制": "Gear Control",
  "设置值": "Set Value",
  "设置低速后退比例": "Set Low-speed Reverse Rate",
  "设置低速前进比例": "Set Low-speed Forward Rate",
  "设置高速后退比例": "Set High-speed Reverse Rate",
  "设置高速前进比例": "Set High-speed Forward Rate",
  "开启": "Enable",
  "关闭": "Disable",
  "体感类型": "Motion Control Type",
  "中": "Center",
  "状态 1": "State 1",
  "状态 2": "State 2",
  "状态 3": "State 3",
  "状态 4": "State 4",
  "状态 5": "State 5",
  "自定义名称": "Custom Name",
  "方向+油门": "Steering + Throttle",
  "前进最大角度": "Max Forward Angle",
  "后退最大角度": "Max Reverse Angle",
  "左转最大角度": "Max Left-turn Angle",
  "右转最大角度": "Max Right-turn Angle",
  "油门零位": "Throttle Center",
  "方向零位": "Steering Center",
  "复位": "Reset",
  "测试模式": "Test Mode",
  "恢复": "Restore",
  "恢复失败": "Restore Failed",
  "蓝牙已断开，接收机将进入失控保护状态。\n点击“恢复”后将扫描并重新连接蓝牙。":
      "Bluetooth is disconnected. The receiver has entered fail-safe mode.\nTap Restore to scan and reconnect Bluetooth.",
  "未能重新连接蓝牙，请确认接收机已上电后再次点击 TEST 恢复。":
      "Unable to reconnect Bluetooth. Make sure the receiver is powered on, then tap TEST again.",
  "设备未就绪": "Device Not Ready",
  "暂时无法读取设备信息，失控保护参数还不能读取或写入，请稍后重试。":
      "Device information is unavailable. Fail-safe settings cannot be read or written yet. Please try again later.",
  "固件更新中…": "Updating Firmware…",
  "固件更新成功！": "Firmware Updated Successfully!",
  "更新失败！": "Update Failed!",
  "最多5个字": "Up to 5 characters",
  "接收机演示固件": "Receiver Demo Firmware",
  "取消配对": "Cancel Pairing",
  "正在配对，请确认接收机处于蓝牙模式\n（LED灯常亮2秒灭一秒）":
      "Pairing… Please make sure the receiver is in Bluetooth mode\n(LED on for 2 seconds, off for 1 second).",
  "自定义X控制校准\n根据右图示意和实时旋转角度\n参考，请前后转动手机选择适\n合自己的控制角度，并输入对\n应控制角度完成自定义控制校\n准。":
      "Custom X Control Calibration\nUse the diagram and live angle\nreference. Tilt the phone forward\nor backward to choose a suitable\ncontrol angle, then enter it to\ncomplete calibration.",
  "蓝牙接收机连接说明": "Bluetooth Receiver Connection Guide",
  "扫描、连接和控制前的准备步骤。":
      "Preparation steps before scanning, connecting, and controlling.",
  "1. 给接收机上电并确认蓝牙模式已经打开。\n2. 在 App 首页进入“去配对”或“已配对设备列表”。\n3. 连接成功后，首页会显示接收机型号和电量信息。\n4. 进入控制页后会以 10ms 周期持续发送控制心跳。":
      "1. Power on the receiver and make sure Bluetooth mode is enabled.\n2. From the Home page, open Pair or the Paired Device List.\n3. After connecting, the Home page shows receiver model and battery information.\n4. The Control page continuously sends control heartbeats every 10 ms.",
  "失控保护说明": "Fail-safe Guide",
  "固定值与保持模式的区别。": "Difference between Fixed Value and Hold modes.",
  "失控保护支持“固定值”和“保持”两种模式。\n固定值会在链路断开后输出你设置的 PWM 值。\n保持模式会让接收机维持当前通道输出。\n修改前请确保车辆处于安全状态。":
      "Fail-safe supports Fixed Value and Hold modes.\nFixed Value outputs your configured PWM value after the link disconnects.\nHold keeps the current channel output.\nMake sure the vehicle is in a safe state before making changes.",
  "固件升级说明": "Firmware Update Guide",
  "演示固件升级流程与注意事项。": "Demo firmware update steps and precautions.",
  "升级流程会先读取接收机信息，再让接收机进入 Boot 模式。\n升级过程中请不要断电，也不要离开升级页面。\n若页面提示失败，请重新连接接收机并再次尝试。":
      "The update first reads receiver information, then puts the receiver into Boot mode.\nDo not power off or leave the update page during the update.\nIf it fails, reconnect the receiver and try again.",
};
