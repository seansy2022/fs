import 'dart:typed_data';

enum ReceiverConnectionState { disconnected, scanning, connecting, connected }

class ReceiverScanConnectCancelledException implements Exception {
  const ReceiverScanConnectCancelledException();
}

enum ReceiverUpgradeStage {
  idle,
  enteringBoot,
  waitingBootReconnect,
  sendingLength,
  sendingPayload,
  completed,
  failed,
}

class ReceiverScanDevice {
  const ReceiverScanDevice({
    required this.remoteId,
    required this.name,
    required this.rssi,
    this.connected = false,
  });

  final String remoteId;
  final String name;
  final int rssi;
  final bool connected;

  ReceiverScanDevice copyWith({
    String? remoteId,
    String? name,
    int? rssi,
    bool? connected,
  }) {
    return ReceiverScanDevice(
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      connected: connected ?? this.connected,
    );
  }
}

class ReceiverInfo {
  const ReceiverInfo({
    required this.rfmId,
    required this.productModelCode,
    required this.batteryLevel,
    this.remoteId,
  });

  final Uint8List rfmId;
  final int productModelCode;
  final int batteryLevel;
  final String? remoteId;

  String get rfmIdHex => rfmId
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();

  String get modelLabel =>
      'RFM-${productModelCode.toRadixString(16).padLeft(4, '0').toUpperCase()}';

  ReceiverInfo copyWith({
    Uint8List? rfmId,
    int? productModelCode,
    int? batteryLevel,
    String? remoteId,
  }) {
    return ReceiverInfo(
      rfmId: rfmId ?? this.rfmId,
      productModelCode: productModelCode ?? this.productModelCode,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      remoteId: remoteId ?? this.remoteId,
    );
  }
}

class ReceiverControlValues {
  const ReceiverControlValues({
    this.throttle = 1500,
    this.steering = 1500,
    this.auxChannels = const [1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500],
  });

  final int throttle;
  final int steering;
  final List<int> auxChannels;

  ReceiverControlValues sanitize() {
    final normalized = List<int>.generate(
      8,
      (index) =>
          _clampAuxChannel(index < auxChannels.length ? auxChannels[index] : 0),
      growable: false,
    );
    return ReceiverControlValues(
      throttle: _clampChannel(throttle),
      steering: _clampChannel(steering),
      auxChannels: normalized,
    );
  }

  ReceiverControlValues copyWith({
    int? throttle,
    int? steering,
    List<int>? auxChannels,
  }) {
    return ReceiverControlValues(
      throttle: throttle ?? this.throttle,
      steering: steering ?? this.steering,
      auxChannels: auxChannels ?? this.auxChannels,
    ).sanitize();
  }

  static int _clampChannel(int value) => value.clamp(1000, 2000);

  /// 辅助通道允许扩展行程，0 仍表示未定义通道。
  static int _clampAuxChannel(int value) {
    if (value == 0) {
      return 0;
    }
    return value.clamp(900, 2100);
  }
}

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
  });

  final int throttleUs;
  final int steeringUs;
  final int ch3Us;
  final int ch4Us;
  final bool throttleHold;
  final bool steeringHold;
  final bool ch3Hold;
  final bool ch4Hold;

  /// 复制失控保护配置，并保留未指定通道的原始值。
  ReceiverFailsafeConfig copyWith({
    int? throttleUs,
    int? steeringUs,
    int? ch3Us,
    int? ch4Us,
    bool? throttleHold,
    bool? steeringHold,
    bool? ch3Hold,
    bool? ch4Hold,
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
    );
  }
}

class ReceiverFirmwareInfo {
  const ReceiverFirmwareInfo({
    required this.productModelCode,
    required this.firmwareVersionCode,
  });

  final int productModelCode;
  final int firmwareVersionCode;

  String get modelLabel =>
      'RFM-${productModelCode.toRadixString(16).padLeft(4, '0').toUpperCase()}';

  String get versionLabel {
    final major = (firmwareVersionCode >> 8) & 0xFF;
    final minor = firmwareVersionCode & 0xFF;
    return '$major.$minor';
  }
}

class ReceiverUpgradeProgress {
  const ReceiverUpgradeProgress({
    required this.stage,
    required this.sentChunks,
    required this.totalChunks,
    this.message,
  });

  final ReceiverUpgradeStage stage;
  final int sentChunks;
  final int totalChunks;
  final String? message;

  bool get isComplete => stage == ReceiverUpgradeStage.completed;

  double get fraction {
    if (totalChunks <= 0) {
      return stage == ReceiverUpgradeStage.completed ? 1 : 0;
    }
    return (sentChunks / totalChunks).clamp(0, 1);
  }
}
