import 'package:rc_c_ble/rc_c_ble.dart';

/// 将被禁用的 CH3 或 CH4 写入失控保护中位值，并保留其他通道配置。
Future<void> syncDisabledAuxFailsafe({
  required ReceiverRepository repository,
  required int channelIndex,
}) async {
  if (channelIndex < 2 || channelIndex > 3) {
    throw ArgumentError.value(channelIndex, 'channelIndex', '只支持 CH3 或 CH4');
  }
  if (repository.receiverInfo == null) {
    await repository.readReceiverInfo();
  }
  final current = await repository.readFailsafe();
  // writeFailsafe 会全量发送，并保留当前 CH5–CH10 的原始协议值。
  final next = channelIndex == 2
      ? current.copyWith(ch3Us: 1500, ch3Hold: false)
      : current.copyWith(ch4Us: 1500, ch4Hold: false);
  await repository.writeFailsafe(next);
}
