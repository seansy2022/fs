// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MG11助手';

  @override
  String get tabHome => '首页';

  @override
  String get tabMenu => '菜单';

  @override
  String get tabBluetooth => '蓝牙';

  @override
  String get homeMenu => '菜单';

  @override
  String get homeAvailableDevices => '可用设备';

  @override
  String get deviceConnected => '设备已连接';

  @override
  String get deviceDisconnected => '设备未连接';

  @override
  String get txVoltage => 'TX电压';

  @override
  String get rxVoltage => 'RX电压';

  @override
  String get signalStrength => '信号强度';

  @override
  String get channelReverse => '通道反向';

  @override
  String get channelTravel => '通道行程';

  @override
  String get subtrim => '中立微调';

  @override
  String get dualRate => '双比率';

  @override
  String get curve => '曲线';

  @override
  String get controlAssign => '控件分配';

  @override
  String get modelSelect => '模型选择';

  @override
  String get failsafe => '失控保护';

  @override
  String get radioSettings => '遥控器设置';

  @override
  String get mixing => '混控';

  @override
  String get bluetoothConnect => '蓝牙连接';

  @override
  String get rev => '反向';

  @override
  String get nor => '正向';

  @override
  String get steeringRate => '方向比率';

  @override
  String get forwardRate => '前进比率';

  @override
  String get brakeRate => '刹车比率';

  @override
  String get steeringCurve => '方向曲线';

  @override
  String get forwardCurve => '前进曲线';

  @override
  String get brakeCurve => '刹车曲线';

  @override
  String get backlightTimeout => '背光时间';

  @override
  String get standbyTimeout => '闲置报警';

  @override
  String get ambientLight => '氛围灯';

  @override
  String get fourWheelSteering => '四轮转向';

  @override
  String get trackMixing => '履带混控';

  @override
  String get driveMixing => '驱动混控';

  @override
  String get brakeMixing => '刹车混控';

  @override
  String get control => '控件';

  @override
  String get type => '类型';

  @override
  String get functionMode => '功能模式';

  @override
  String get mode => '模式';

  @override
  String get notSet => '未设置';

  @override
  String get trigger => '触发';

  @override
  String get flip => '翻转';

  @override
  String get singlePress => '单击';

  @override
  String get doublePress => '双击';

  @override
  String get triplePress => '三击';

  @override
  String get longPress => '长按';

  @override
  String get knob => '旋钮';

  @override
  String get twoPos => '2档';

  @override
  String get threePos => '3档';

  @override
  String get fourWsModeSwitch => '四轮转向模式切换';

  @override
  String get fourWsFront => '四轮转向前面';

  @override
  String get fourWsRear => '四轮转向后面';

  @override
  String get fourWsSame => '四轮转向前后同向';

  @override
  String get fourWsRev => '四轮转向前后反向';

  @override
  String get driveMixModeSwitch => '驱动混控模式切换';

  @override
  String get driveMixFR => '驱动混控前后混控';

  @override
  String get driveMixF => '驱动混控前面';

  @override
  String get driveMixR => '驱动混控后面';

  @override
  String get driveMixFRate => '驱动混控前进比率';

  @override
  String get driveMixRrate => '驱动混控后退比率';

  @override
  String get fourWsRate => '四轮转向比率';

  @override
  String get steeringTrim => '方向微调';

  @override
  String get throttleTrim => '油门微调';

  @override
  String get none => '无';

  @override
  String modelName(int index) {
    return '模型$index名称';
  }

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get ok => '确定';

  @override
  String get standbyTimeoutLabel => '闲置报警';

  @override
  String get ambientLightLabel => '氛围灯';

  @override
  String get reset => '复位';

  @override
  String get mixingChannel => '混控通道';

  @override
  String get mixingRatio => '混控比率';

  @override
  String get front => '前面';

  @override
  String get rear => '后面';

  @override
  String get frontRearSame => '前后同向';

  @override
  String get frontRearRev => '前后反向';

  @override
  String get trackMixLabel => '履带混控';

  @override
  String get driveMixLabel => '驱动混控';

  @override
  String get fDrive => '后驱';

  @override
  String get rDrive => '前驱';

  @override
  String get frDrive => '前后混驱';

  @override
  String get brakeMixingLabel => '刹车混控';

  @override
  String get duplicateAssignWarning => '已重复分配功能，前一个分配该功能的控件功能模式将会变成\"无\"';

  @override
  String get confirmFactoryReset => '确认恢复出厂设置?';

  @override
  String get scanning => '搜索中...';

  @override
  String get noDevices => '无可用设备';

  @override
  String get bluetoothOff => '未开启蓝牙!';

  @override
  String get turnOnBluetooth => '开启蓝牙';

  @override
  String get startScanning => '开始扫描';

  @override
  String get tapToScan => '点击下方按钮开始扫描';

  @override
  String get permissionNotGranted => '权限未开启';

  @override
  String get grantLocationBtPermission => '请开启定位和蓝牙权限';

  @override
  String get grantBtPermission => '请开启蓝牙相关权限';

  @override
  String get grantPermission => '开启权限';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '未连接';

  @override
  String get searching => '搜索中';

  @override
  String get searchingNearby => '正在搜索附近蓝牙设备...';

  @override
  String get later => '稍后';

  @override
  String get goToSettings => '去开启';

  @override
  String get prompt => '输入提示语';

  @override
  String get noDevice => '暂无设备';

  @override
  String get connecting => '设备连接中...';

  @override
  String get connectedSuccess => '设备连接成功!';

  @override
  String get connectFailed => '设备连接失败!';

  @override
  String get logSettings => '日志设置';

  @override
  String get bluetoothLog => '蓝牙日志';

  @override
  String get readDeviceDataFailed => '读取设备数据失败，请重试';

  @override
  String get connectionTimeout => '连接超时，请重试';

  @override
  String get restoredDefaults => '已恢复默认值，当前未连接设备，未发送到设备';

  @override
  String get readDeviceFailed => '读取设备数据失败';

  @override
  String get turnLeft => '左转';

  @override
  String get forward => '前进';

  @override
  String get back => '后退';

  @override
  String get turnRight => '右转';

  @override
  String get frontDrive => '前驱';

  @override
  String get rearDrive => '后驱';

  @override
  String get mixedDrive => '前后混驱';

  @override
  String get mixingCurve => '混控曲线';

  @override
  String get lowSpeed => '低速';

  @override
  String get highSpeed => '高速';

  @override
  String get language => '语言';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get functionForward => '功能:向前';

  @override
  String get functionCenter => '功能:向中';

  @override
  String get functionBackward => '功能:向后';

  @override
  String get duplicateTitle => '提示';

  @override
  String get restoreDefaultsTitle => '恢复出厂设置';

  @override
  String get channelOutput => '通道输出';

  @override
  String get mixingFunctionSwitch => '混控功能切换';

  @override
  String get fourWsSwitch => '四轮转向开关';

  @override
  String get trackSwitch => '履带混控开关';

  @override
  String get driveSwitch => '驱动混控开关';

  @override
  String get brakeSwitch => '刹车混控开关';
}
