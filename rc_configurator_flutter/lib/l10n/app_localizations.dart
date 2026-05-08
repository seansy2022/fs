import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MG11 Assistant'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get tabHome;

  /// No description provided for @tabMenu.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get tabMenu;

  /// No description provided for @tabBluetooth.
  ///
  /// In en, this message translates to:
  /// **'BT'**
  String get tabBluetooth;

  /// No description provided for @homeMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenu;

  /// No description provided for @homeAvailableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available devices'**
  String get homeAvailableDevices;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Device connected'**
  String get deviceConnected;

  /// No description provided for @deviceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get deviceDisconnected;

  /// No description provided for @txVoltage.
  ///
  /// In en, this message translates to:
  /// **'TX voltage'**
  String get txVoltage;

  /// No description provided for @rxVoltage.
  ///
  /// In en, this message translates to:
  /// **'RX voltage'**
  String get rxVoltage;

  /// No description provided for @signalStrength.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get signalStrength;

  /// No description provided for @channelReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get channelReverse;

  /// No description provided for @channelTravel.
  ///
  /// In en, this message translates to:
  /// **'EPA'**
  String get channelTravel;

  /// No description provided for @subtrim.
  ///
  /// In en, this message translates to:
  /// **'SUBTRIM'**
  String get subtrim;

  /// No description provided for @dualRate.
  ///
  /// In en, this message translates to:
  /// **'D/R'**
  String get dualRate;

  /// No description provided for @curve.
  ///
  /// In en, this message translates to:
  /// **'CURVE'**
  String get curve;

  /// No description provided for @controlAssign.
  ///
  /// In en, this message translates to:
  /// **'ASSIGN'**
  String get controlAssign;

  /// No description provided for @modelSelect.
  ///
  /// In en, this message translates to:
  /// **'MODEL'**
  String get modelSelect;

  /// No description provided for @failsafe.
  ///
  /// In en, this message translates to:
  /// **'Failsafe'**
  String get failsafe;

  /// No description provided for @radioSettings.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get radioSettings;

  /// No description provided for @mixing.
  ///
  /// In en, this message translates to:
  /// **'MIXES'**
  String get mixing;

  /// No description provided for @bluetoothConnect.
  ///
  /// In en, this message translates to:
  /// **'BT Connect'**
  String get bluetoothConnect;

  /// No description provided for @rev.
  ///
  /// In en, this message translates to:
  /// **'REV'**
  String get rev;

  /// No description provided for @nor.
  ///
  /// In en, this message translates to:
  /// **'NOR'**
  String get nor;

  /// No description provided for @steeringRate.
  ///
  /// In en, this message translates to:
  /// **'ST Rate'**
  String get steeringRate;

  /// No description provided for @forwardRate.
  ///
  /// In en, this message translates to:
  /// **'Forward Rate'**
  String get forwardRate;

  /// No description provided for @brakeRate.
  ///
  /// In en, this message translates to:
  /// **'Brake Rate'**
  String get brakeRate;

  /// No description provided for @steeringCurve.
  ///
  /// In en, this message translates to:
  /// **'ST Curve'**
  String get steeringCurve;

  /// No description provided for @forwardCurve.
  ///
  /// In en, this message translates to:
  /// **'Forward Curve'**
  String get forwardCurve;

  /// No description provided for @brakeCurve.
  ///
  /// In en, this message translates to:
  /// **'Brake Curve'**
  String get brakeCurve;

  /// No description provided for @backlightTimeout.
  ///
  /// In en, this message translates to:
  /// **'Backlight Timeout'**
  String get backlightTimeout;

  /// No description provided for @standbyTimeout.
  ///
  /// In en, this message translates to:
  /// **'Standby Timeout'**
  String get standbyTimeout;

  /// No description provided for @ambientLight.
  ///
  /// In en, this message translates to:
  /// **'Ambient Light'**
  String get ambientLight;

  /// No description provided for @fourWheelSteering.
  ///
  /// In en, this message translates to:
  /// **'4WS'**
  String get fourWheelSteering;

  /// No description provided for @trackMixing.
  ///
  /// In en, this message translates to:
  /// **'Track Mix'**
  String get trackMixing;

  /// No description provided for @driveMixing.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix'**
  String get driveMixing;

  /// No description provided for @brakeMixing.
  ///
  /// In en, this message translates to:
  /// **'Brake Mixing'**
  String get brakeMixing;

  /// No description provided for @control.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get control;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @functionMode.
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get functionMode;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @trigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get trigger;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flip;

  /// No description provided for @singlePress.
  ///
  /// In en, this message translates to:
  /// **'Single press'**
  String get singlePress;

  /// No description provided for @doublePress.
  ///
  /// In en, this message translates to:
  /// **'Double press'**
  String get doublePress;

  /// No description provided for @triplePress.
  ///
  /// In en, this message translates to:
  /// **'Triple press'**
  String get triplePress;

  /// No description provided for @longPress.
  ///
  /// In en, this message translates to:
  /// **'Long press'**
  String get longPress;

  /// No description provided for @knob.
  ///
  /// In en, this message translates to:
  /// **'Knob'**
  String get knob;

  /// No description provided for @twoPos.
  ///
  /// In en, this message translates to:
  /// **'2 POS'**
  String get twoPos;

  /// No description provided for @threePos.
  ///
  /// In en, this message translates to:
  /// **'3 POS'**
  String get threePos;

  /// No description provided for @fourWsModeSwitch.
  ///
  /// In en, this message translates to:
  /// **'4WS Mixing Mode'**
  String get fourWsModeSwitch;

  /// No description provided for @fourWsFront.
  ///
  /// In en, this message translates to:
  /// **'4WS Mixing Front'**
  String get fourWsFront;

  /// No description provided for @fourWsRear.
  ///
  /// In en, this message translates to:
  /// **'4WS Mixing Rear'**
  String get fourWsRear;

  /// No description provided for @fourWsSame.
  ///
  /// In en, this message translates to:
  /// **'4WS Mixing Same'**
  String get fourWsSame;

  /// No description provided for @fourWsRev.
  ///
  /// In en, this message translates to:
  /// **'4WS Mixing Rev.'**
  String get fourWsRev;

  /// No description provided for @driveMixModeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix Mode'**
  String get driveMixModeSwitch;

  /// No description provided for @driveMixFR.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix F-R Drive'**
  String get driveMixFR;

  /// No description provided for @driveMixF.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix F Drive'**
  String get driveMixF;

  /// No description provided for @driveMixR.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix R Drive'**
  String get driveMixR;

  /// No description provided for @driveMixFRate.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix F Rate'**
  String get driveMixFRate;

  /// No description provided for @driveMixRrate.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix R Rate'**
  String get driveMixRrate;

  /// No description provided for @fourWsRate.
  ///
  /// In en, this message translates to:
  /// **'4WS Mixing Rate'**
  String get fourWsRate;

  /// No description provided for @steeringTrim.
  ///
  /// In en, this message translates to:
  /// **'Steering Trim'**
  String get steeringTrim;

  /// No description provided for @throttleTrim.
  ///
  /// In en, this message translates to:
  /// **'Throttle Trim'**
  String get throttleTrim;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'Model{index} Name'**
  String modelName(int index);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Sure'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @standbyTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Standby Timeout'**
  String get standbyTimeoutLabel;

  /// No description provided for @ambientLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Ambient Light'**
  String get ambientLightLabel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @mixingChannel.
  ///
  /// In en, this message translates to:
  /// **'Mix Channel'**
  String get mixingChannel;

  /// No description provided for @mixingRatio.
  ///
  /// In en, this message translates to:
  /// **'Mix Rate'**
  String get mixingRatio;

  /// No description provided for @front.
  ///
  /// In en, this message translates to:
  /// **'F-ST'**
  String get front;

  /// No description provided for @rear.
  ///
  /// In en, this message translates to:
  /// **'R-ST'**
  String get rear;

  /// No description provided for @frontRearSame.
  ///
  /// In en, this message translates to:
  /// **'FR-S'**
  String get frontRearSame;

  /// No description provided for @frontRearRev.
  ///
  /// In en, this message translates to:
  /// **'FR-R'**
  String get frontRearRev;

  /// No description provided for @trackMixLabel.
  ///
  /// In en, this message translates to:
  /// **'Track Mix'**
  String get trackMixLabel;

  /// No description provided for @driveMixLabel.
  ///
  /// In en, this message translates to:
  /// **'Drive Mix'**
  String get driveMixLabel;

  /// No description provided for @fDrive.
  ///
  /// In en, this message translates to:
  /// **'F-R Drive'**
  String get fDrive;

  /// No description provided for @rDrive.
  ///
  /// In en, this message translates to:
  /// **'F Drive'**
  String get rDrive;

  /// No description provided for @frDrive.
  ///
  /// In en, this message translates to:
  /// **'R Drive'**
  String get frDrive;

  /// No description provided for @brakeMixingLabel.
  ///
  /// In en, this message translates to:
  /// **'Brake Mixing'**
  String get brakeMixingLabel;

  /// No description provided for @duplicateAssignWarning.
  ///
  /// In en, this message translates to:
  /// **'Duplicate assignment. Previous control will be set to \"None\".'**
  String get duplicateAssignWarning;

  /// No description provided for @confirmFactoryReset.
  ///
  /// In en, this message translates to:
  /// **'Confirm factory reset?'**
  String get confirmFactoryReset;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices available'**
  String get noDevices;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off!'**
  String get bluetoothOff;

  /// No description provided for @turnOnBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth'**
  String get turnOnBluetooth;

  /// No description provided for @startScanning.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get startScanning;

  /// No description provided for @tapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to start scanning'**
  String get tapToScan;

  /// No description provided for @permissionNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission not granted'**
  String get permissionNotGranted;

  /// No description provided for @grantLocationBtPermission.
  ///
  /// In en, this message translates to:
  /// **'Please grant location and Bluetooth permissions'**
  String get grantLocationBtPermission;

  /// No description provided for @grantBtPermission.
  ///
  /// In en, this message translates to:
  /// **'Please grant Bluetooth permissions'**
  String get grantBtPermission;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermission;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get searching;

  /// No description provided for @searchingNearby.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby Bluetooth devices...'**
  String get searchingNearby;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to settings'**
  String get goToSettings;

  /// No description provided for @prompt.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get prompt;

  /// No description provided for @noDevice.
  ///
  /// In en, this message translates to:
  /// **'No devices'**
  String get noDevice;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected!'**
  String get connectedSuccess;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed!'**
  String get connectFailed;

  /// No description provided for @logSettings.
  ///
  /// In en, this message translates to:
  /// **'Log Settings'**
  String get logSettings;

  /// No description provided for @bluetoothLog.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Log'**
  String get bluetoothLog;

  /// No description provided for @readDeviceDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read device data, please retry'**
  String get readDeviceDataFailed;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out, please retry'**
  String get connectionTimeout;

  /// No description provided for @restoredDefaults.
  ///
  /// In en, this message translates to:
  /// **'Defaults restored. Device not connected, not sent to device.'**
  String get restoredDefaults;

  /// No description provided for @readDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read device data'**
  String get readDeviceFailed;

  /// No description provided for @turnLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get turnLeft;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get forward;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @turnRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get turnRight;

  /// No description provided for @frontDrive.
  ///
  /// In en, this message translates to:
  /// **'F Drive'**
  String get frontDrive;

  /// No description provided for @rearDrive.
  ///
  /// In en, this message translates to:
  /// **'R Drive'**
  String get rearDrive;

  /// No description provided for @mixedDrive.
  ///
  /// In en, this message translates to:
  /// **'F-R Drive'**
  String get mixedDrive;

  /// No description provided for @mixingCurve.
  ///
  /// In en, this message translates to:
  /// **'Mix Curve'**
  String get mixingCurve;

  /// No description provided for @lowSpeed.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get lowSpeed;

  /// No description provided for @highSpeed.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get highSpeed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @functionForward.
  ///
  /// In en, this message translates to:
  /// **'Function: Forward'**
  String get functionForward;

  /// No description provided for @functionCenter.
  ///
  /// In en, this message translates to:
  /// **'Function: Center'**
  String get functionCenter;

  /// No description provided for @functionBackward.
  ///
  /// In en, this message translates to:
  /// **'Function: Backward'**
  String get functionBackward;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get duplicateTitle;

  /// No description provided for @restoreDefaultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get restoreDefaultsTitle;

  /// No description provided for @channelOutput.
  ///
  /// In en, this message translates to:
  /// **'Channel Output'**
  String get channelOutput;

  /// No description provided for @mixingFunctionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Mix Func Switch'**
  String get mixingFunctionSwitch;

  /// No description provided for @fourWsSwitch.
  ///
  /// In en, this message translates to:
  /// **'4WS Switch'**
  String get fourWsSwitch;

  /// No description provided for @trackSwitch.
  ///
  /// In en, this message translates to:
  /// **'Track Switch'**
  String get trackSwitch;

  /// No description provided for @driveSwitch.
  ///
  /// In en, this message translates to:
  /// **'Drive Switch'**
  String get driveSwitch;

  /// No description provided for @brakeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Brake Switch'**
  String get brakeSwitch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
