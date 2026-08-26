import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_ui/rc_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/providers.dart';
import '../../models/gyro_calibration_settings.dart';
import '../../widgets/settings_action_button.dart';
import 'gyro_axis_calibration_panel.dart';
import 'gyro_calibration_exit_dialog.dart';
import 'package:controller_app/src/core/localization/app_localizations.dart';

/// 体感校准页面：编辑校准点，并实时展示手机前后、左右的姿态角。
class GyroCalibrationPage extends ConsumerStatefulWidget {
  const GyroCalibrationPage({super.key});

  @override
  ConsumerState<GyroCalibrationPage> createState() =>
      _GyroCalibrationPageState();
}

class _GyroCalibrationPageState extends ConsumerState<GyroCalibrationPage> {
  late final _DegreeControllers _controllers;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _throttleDegree = 0;
  double _steeringDegree = 0;

  @override
  void initState() {
    super.initState();
    _controllers = _DegreeControllers(
      ref.read(appSettingsProvider).gyroCalibration,
    );
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onAccelerometerEvent);
  }

  /// 使用控制页相同的坐标系，分别换算前后倾斜和左右倾斜角度。
  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!mounted) {
      return;
    }
    setState(() {
      _throttleDegree = -_degree(math.atan2(event.x, event.z));
      _steeringDegree = _degree(math.atan2(event.y, event.z));
    });
  }

  /// 仅恢复本页草稿到默认值，用户点击保存后才写入本地设置。
  void _resetDraft() {
    _controllers.setValue(GyroCalibrationSettings.defaults);
  }

  /// 校验六个输入点并持久化，返回是否成功保存。
  bool _saveDraft() {
    final value = _controllers.value;
    if (value == null || !value.isValid) {
      return false;
    }
    ref.read(appSettingsProvider.notifier).updateGyroCalibration(value);
    return true;
  }

  /// 点击保存按钮时，成功保存后退出校准页。
  Future<void> _saveAndClose() async {
    if (!_saveDraft()) {
      return;
    }
    await showGyroCalibrationSaveSuccessDialog(context);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 点击保存按钮时，异步展示成功提示后退出校准页。
  void _save() => unawaited(_saveAndClose());

  /// 只有草稿被修改时，才在退出前询问是否保存。
  Future<void> _requestClose() async {
    if (_controllers.matches(ref.read(appSettingsProvider).gyroCalibration)) {
      Navigator.of(context).pop();
      return;
    }
    final shouldSave = await showGyroCalibrationExitDialog(context);
    if (!mounted || !shouldSave) {
      return;
    }
    await _saveAndClose();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechShell(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _CalibrationTopBar(onClose: () => unawaited(_requestClose())),
                // 与设置页顶部栏保持同一组垂直节奏。
                const SizedBox(height: 12),
                const _CalibrationDivider(),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    color: AppColors.surfaceHighest.withValues(alpha: 0.42),
                    child: Row(
                      children: [
                        Expanded(
                          child: GyroAxisCalibrationPanel(
                            title: '油门校准',
                            currentDegree: _throttleDegree,
                            inputs: [
                              GyroDegreeInputData(
                                label: '前进最大角度',
                                controller: _controllers.throttleForward,
                              ),
                              GyroDegreeInputData(
                                label: '油门零位',
                                controller: _controllers.throttleCenter,
                              ),
                              GyroDegreeInputData(
                                label: '后退最大角度',
                                controller: _controllers.throttleReverse,
                              ),
                            ],
                            isInputValid: _controllers.isInputValid,
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: GyroAxisCalibrationPanel(
                            title: '方向校准',
                            currentDegree: _steeringDegree,
                            inputs: [
                              GyroDegreeInputData(
                                label: '左转最大角度',
                                controller: _controllers.steeringLeft,
                              ),
                              GyroDegreeInputData(
                                label: '方向零位',
                                controller: _controllers.steeringCenter,
                              ),
                              GyroDegreeInputData(
                                label: '右转最大角度',
                                controller: _controllers.steeringRight,
                              ),
                            ],
                            isInputValid: _controllers.isInputValid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CalibrationActions(onReset: _resetDraft, onSave: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalibrationTopBar extends StatelessWidget {
  const _CalibrationTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          AppText.tr('体感校准：'),
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: AppFonts.w700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppText.tr('可通过此功能，校准最大通道行程对应的陀螺仪角度'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(Icons.close, color: AppColors.text, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalibrationDivider extends StatelessWidget {
  const _CalibrationDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7EA2CF),
            Color(0xFF00C8FF),
            Color(0xFF92FE9D),
            Color(0xFF00C8FF),
            Color(0xFF7DA2CE),
          ],
          stops: [0, .3334, .5092, .678, 1],
        ),
      ),
    );
  }
}

class _CalibrationActions extends StatelessWidget {
  const _CalibrationActions({required this.onReset, required this.onSave});

  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsActionButton(
            label: AppText.tr('复位'),
            onTap: onReset,
            width: 106,
            height: 32,
          ),
          const SizedBox(width: 20),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSave,
            child: Container(
              width: 106,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryBright, AppColors.primary],
                ),
              ),
              child: Text(
                AppText.tr('保存'),
                style: TextStyle(color: AppColors.bg, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DegreeControllers {
  _DegreeControllers(GyroCalibrationSettings value)
    : throttleForward = _controller(value.throttleForwardDegree),
      throttleCenter = _controller(value.throttleCenterDegree),
      throttleReverse = _controller(value.throttleReverseDegree),
      steeringLeft = _controller(value.steeringLeftDegree),
      steeringCenter = _controller(value.steeringCenterDegree),
      steeringRight = _controller(value.steeringRightDegree);

  final TextEditingController throttleForward;
  final TextEditingController throttleCenter;
  final TextEditingController throttleReverse;
  final TextEditingController steeringLeft;
  final TextEditingController steeringCenter;
  final TextEditingController steeringRight;

  GyroCalibrationSettings? get value => _valueFor();

  /// 用候选值替换单个输入框后，判断六个校准点是否仍满足约束。
  bool isInputValid(TextEditingController controller, String candidate) {
    return _valueFor(
          replacement: controller,
          replacementText: candidate,
        )?.isValid ??
        false;
  }

  /// 统一解析当前草稿或包含候选输入值的草稿，避免提前写入无效值。
  GyroCalibrationSettings? _valueFor({
    TextEditingController? replacement,
    String? replacementText,
  }) {
    final values =
        [
          throttleForward,
          throttleCenter,
          throttleReverse,
          steeringLeft,
          steeringCenter,
          steeringRight,
        ].map((controller) {
          final text = identical(controller, replacement)
              ? replacementText
              : controller.text;
          return double.tryParse(text ?? '');
        }).toList();
    if (values.any((value) => value == null)) {
      return null;
    }
    return GyroCalibrationSettings(
      throttleForwardDegree: values[0]!,
      throttleCenterDegree: values[1]!,
      throttleReverseDegree: values[2]!,
      steeringLeftDegree: values[3]!,
      steeringCenterDegree: values[4]!,
      steeringRightDegree: values[5]!,
    );
  }

  /// 判断当前六个编辑值是否仍与已保存的校准值相同。
  bool matches(GyroCalibrationSettings saved) {
    final draft = value;
    return draft != null &&
        draft.throttleForwardDegree == saved.throttleForwardDegree &&
        draft.throttleCenterDegree == saved.throttleCenterDegree &&
        draft.throttleReverseDegree == saved.throttleReverseDegree &&
        draft.steeringLeftDegree == saved.steeringLeftDegree &&
        draft.steeringCenterDegree == saved.steeringCenterDegree &&
        draft.steeringRightDegree == saved.steeringRightDegree;
  }

  /// 将持久化值格式化回当前页面的六个编辑框。
  void setValue(GyroCalibrationSettings value) {
    throttleForward.text = _format(value.throttleForwardDegree);
    throttleCenter.text = _format(value.throttleCenterDegree);
    throttleReverse.text = _format(value.throttleReverseDegree);
    steeringLeft.text = _format(value.steeringLeftDegree);
    steeringCenter.text = _format(value.steeringCenterDegree);
    steeringRight.text = _format(value.steeringRightDegree);
  }

  void dispose() {
    throttleForward.dispose();
    throttleCenter.dispose();
    throttleReverse.dispose();
    steeringLeft.dispose();
    steeringCenter.dispose();
    steeringRight.dispose();
  }

  static TextEditingController _controller(double value) {
    return TextEditingController(text: _format(value));
  }

  static String _format(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }
}

double _degree(double radians) => radians * 180 / math.pi;
