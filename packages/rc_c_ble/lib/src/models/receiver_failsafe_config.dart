/// 接收机失控保护配置；CH5–CH10 由协议层规范化后保存并回写。
class ReceiverFailsafeConfig {
  const ReceiverFailsafeConfig({
    required this.throttleUs,
    required this.steeringUs,
    this.ch3Us = 1500,
    this.ch4Us = 1500,
    this.throttleHold = false,
    this.steeringHold = false,
    this.ch3Hold = false,
    this.ch4Hold = false,
    this.ch5ToCh10Raw = const <int>[],
  });

  /// 协议使用 0x0FFF 表示通道保持当前输出。
  static const int holdValue = 0x0FFF;

  final int throttleUs;
  final int steeringUs;
  final int ch3Us;
  final int ch4Us;
  final bool throttleHold;
  final bool steeringHold;
  final bool ch3Hold;
  final bool ch4Hold;

  /// CH5–CH10 的 16 位协议值，按通道顺序保存。
  final List<int> ch5ToCh10Raw;

  /// 复制配置；未指定的 CH5–CH10 值始终保留。
  ReceiverFailsafeConfig copyWith({
    int? throttleUs,
    int? steeringUs,
    int? ch3Us,
    int? ch4Us,
    bool? throttleHold,
    bool? steeringHold,
    bool? ch3Hold,
    bool? ch4Hold,
    List<int>? ch5ToCh10Raw,
  }) {
    return ReceiverFailsafeConfig(
      throttleUs: throttleUs ?? this.throttleUs,
      steeringUs: steeringUs ?? this.steeringUs,
      ch3Us: ch3Us ?? this.ch3Us,
      ch4Us: ch4Us ?? this.ch4Us,
      throttleHold: throttleHold ?? this.throttleHold,
      steeringHold: steeringHold ?? this.steeringHold,
      ch3Hold: ch3Hold ?? this.ch3Hold,
      ch4Hold: ch4Hold ?? this.ch4Hold,
      ch5ToCh10Raw: ch5ToCh10Raw ?? this.ch5ToCh10Raw,
    );
  }
}
