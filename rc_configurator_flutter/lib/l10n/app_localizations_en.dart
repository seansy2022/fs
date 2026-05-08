// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MG11 Assistant';

  @override
  String get tabHome => 'HOME';

  @override
  String get tabMenu => 'MENU';

  @override
  String get tabBluetooth => 'BT';

  @override
  String get homeMenu => 'Menu';

  @override
  String get homeAvailableDevices => 'Available devices';

  @override
  String get deviceConnected => 'Device connected';

  @override
  String get deviceDisconnected => 'Device disconnected';

  @override
  String get txVoltage => 'TX voltage';

  @override
  String get rxVoltage => 'RX voltage';

  @override
  String get signalStrength => 'Signal';

  @override
  String get channelReverse => 'Reverse';

  @override
  String get channelTravel => 'EPA';

  @override
  String get subtrim => 'SUBTRIM';

  @override
  String get dualRate => 'D/R';

  @override
  String get curve => 'CURVE';

  @override
  String get controlAssign => 'ASSIGN';

  @override
  String get modelSelect => 'MODEL';

  @override
  String get failsafe => 'Failsafe';

  @override
  String get radioSettings => 'SYSTEM';

  @override
  String get mixing => 'MIXES';

  @override
  String get bluetoothConnect => 'BT Connect';

  @override
  String get rev => 'REV';

  @override
  String get nor => 'NOR';

  @override
  String get steeringRate => 'ST Rate';

  @override
  String get forwardRate => 'Forward Rate';

  @override
  String get brakeRate => 'Brake Rate';

  @override
  String get steeringCurve => 'ST Curve';

  @override
  String get forwardCurve => 'Forward Curve';

  @override
  String get brakeCurve => 'Brake Curve';

  @override
  String get backlightTimeout => 'Backlight Timeout';

  @override
  String get standbyTimeout => 'Standby Timeout';

  @override
  String get ambientLight => 'Ambient Light';

  @override
  String get fourWheelSteering => '4WS';

  @override
  String get trackMixing => 'Track Mix';

  @override
  String get driveMixing => 'Drive Mix';

  @override
  String get brakeMixing => 'Brake Mixing';

  @override
  String get control => 'Control';

  @override
  String get type => 'Type';

  @override
  String get functionMode => 'Function';

  @override
  String get mode => 'Mode';

  @override
  String get notSet => 'Not set';

  @override
  String get trigger => 'Trigger';

  @override
  String get flip => 'Flip';

  @override
  String get singlePress => 'Single press';

  @override
  String get doublePress => 'Double press';

  @override
  String get triplePress => 'Triple press';

  @override
  String get longPress => 'Long press';

  @override
  String get knob => 'Knob';

  @override
  String get twoPos => '2 POS';

  @override
  String get threePos => '3 POS';

  @override
  String get fourWsModeSwitch => '4WS Mixing Mode';

  @override
  String get fourWsFront => '4WS Mixing Front';

  @override
  String get fourWsRear => '4WS Mixing Rear';

  @override
  String get fourWsSame => '4WS Mixing Same';

  @override
  String get fourWsRev => '4WS Mixing Rev.';

  @override
  String get driveMixModeSwitch => 'Drive Mix Mode';

  @override
  String get driveMixFR => 'Drive Mix F-R Drive';

  @override
  String get driveMixF => 'Drive Mix F Drive';

  @override
  String get driveMixR => 'Drive Mix R Drive';

  @override
  String get driveMixFRate => 'Drive Mix F Rate';

  @override
  String get driveMixRrate => 'Drive Mix R Rate';

  @override
  String get fourWsRate => '4WS Mixing Rate';

  @override
  String get steeringTrim => 'Steering Trim';

  @override
  String get throttleTrim => 'Throttle Trim';

  @override
  String get none => 'None';

  @override
  String modelName(int index) {
    return 'Model$index Name';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Sure';

  @override
  String get ok => 'OK';

  @override
  String get standbyTimeoutLabel => 'Standby Timeout';

  @override
  String get ambientLightLabel => 'Ambient Light';

  @override
  String get reset => 'Reset';

  @override
  String get mixingChannel => 'Mix Channel';

  @override
  String get mixingRatio => 'Mix Rate';

  @override
  String get front => 'F-ST';

  @override
  String get rear => 'R-ST';

  @override
  String get frontRearSame => 'FR-S';

  @override
  String get frontRearRev => 'FR-R';

  @override
  String get trackMixLabel => 'Track Mix';

  @override
  String get driveMixLabel => 'Drive Mix';

  @override
  String get fDrive => 'F-R Drive';

  @override
  String get rDrive => 'F Drive';

  @override
  String get frDrive => 'R Drive';

  @override
  String get brakeMixingLabel => 'Brake Mixing';

  @override
  String get duplicateAssignWarning =>
      'Duplicate assignment. Previous control will be set to \"None\".';

  @override
  String get confirmFactoryReset => 'Confirm factory reset?';

  @override
  String get scanning => 'Scanning...';

  @override
  String get noDevices => 'No devices available';

  @override
  String get bluetoothOff => 'Bluetooth is off!';

  @override
  String get turnOnBluetooth => 'Turn on Bluetooth';

  @override
  String get startScanning => 'Start Scan';

  @override
  String get tapToScan => 'Tap the button below to start scanning';

  @override
  String get permissionNotGranted => 'Permission not granted';

  @override
  String get grantLocationBtPermission =>
      'Please grant location and Bluetooth permissions';

  @override
  String get grantBtPermission => 'Please grant Bluetooth permissions';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get searching => 'Scanning...';

  @override
  String get searchingNearby => 'Searching for nearby Bluetooth devices...';

  @override
  String get later => 'Later';

  @override
  String get goToSettings => 'Go to settings';

  @override
  String get prompt => 'Hint';

  @override
  String get noDevice => 'No devices';

  @override
  String get connecting => 'Connecting...';

  @override
  String get connectedSuccess => 'Connected!';

  @override
  String get connectFailed => 'Connection failed!';

  @override
  String get logSettings => 'Log Settings';

  @override
  String get bluetoothLog => 'Bluetooth Log';

  @override
  String get readDeviceDataFailed => 'Failed to read device data, please retry';

  @override
  String get connectionTimeout => 'Connection timed out, please retry';

  @override
  String get restoredDefaults =>
      'Defaults restored. Device not connected, not sent to device.';

  @override
  String get readDeviceFailed => 'Failed to read device data';

  @override
  String get turnLeft => 'Left';

  @override
  String get forward => 'Front';

  @override
  String get back => 'Back';

  @override
  String get turnRight => 'Right';

  @override
  String get frontDrive => 'F Drive';

  @override
  String get rearDrive => 'R Drive';

  @override
  String get mixedDrive => 'F-R Drive';

  @override
  String get mixingCurve => 'Mix Curve';

  @override
  String get lowSpeed => 'LOW';

  @override
  String get highSpeed => 'HIGH';

  @override
  String get language => 'Language';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get functionForward => 'Function: Forward';

  @override
  String get functionCenter => 'Function: Center';

  @override
  String get functionBackward => 'Function: Backward';

  @override
  String get duplicateTitle => 'Info';

  @override
  String get restoreDefaultsTitle => 'Restore defaults';

  @override
  String get channelOutput => 'Channel Output';

  @override
  String get mixingFunctionSwitch => 'Mix Func Switch';

  @override
  String get fourWsSwitch => '4WS Switch';

  @override
  String get trackSwitch => 'Track Switch';

  @override
  String get driveSwitch => 'Drive Switch';

  @override
  String get brakeSwitch => 'Brake Switch';
}
