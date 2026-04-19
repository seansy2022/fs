import 'dart:typed_data';

class DemoFirmwarePackage {
  const DemoFirmwarePackage({
    required this.id,
    required this.label,
    required this.versionLabel,
    required this.size,
    required this.seed,
  });

  final String id;
  final String label;
  final String versionLabel;
  final int size;
  final int seed;

  Uint8List buildBytes() {
    return Uint8List.fromList(
      List<int>.generate(size, (index) => ((index * seed) + 17) % 255),
    );
  }
}

class HelpDocument {
  const HelpDocument({
    required this.title,
    required this.summary,
    required this.body,
  });

  final String title;
  final String summary;
  final String body;
}

const demoFirmwarePackages = <DemoFirmwarePackage>[
  DemoFirmwarePackage(
    id: 'receiver-demo-106',
    label: '接收机演示固件',
    versionLabel: '1.0.6',
    size: 120,
    seed: 7,
  ),
  DemoFirmwarePackage(
    id: 'receiver-demo-107',
    label: '接收机演示固件',
    versionLabel: '1.0.7',
    size: 168,
    seed: 11,
  ),
];

const helpDocuments = <HelpDocument>[
  HelpDocument(
    title: '蓝牙接收机连接说明',
    summary: '扫描、连接和控制前的准备步骤。',
    body:
        '1. 给接收机上电并确认蓝牙模式已经打开。\n'
        '2. 在 App 首页进入“去配对”或“已配对设备列表”。\n'
        '3. 连接成功后，首页会显示接收机型号和电量信息。\n'
        '4. 进入控制页后会以 10ms 周期持续发送控制心跳。',
  ),
  HelpDocument(
    title: '失控保护说明',
    summary: '固定值与保持模式的区别。',
    body:
        '失控保护支持“固定值”和“保持”两种模式。\n'
        '固定值会在链路断开后输出你设置的 PWM 值。\n'
        '保持模式会让接收机维持当前通道输出。\n'
        '修改前请确保车辆处于安全状态。',
  ),
  HelpDocument(
    title: '固件升级说明',
    summary: '演示固件升级流程与注意事项。',
    body:
        '升级流程会先读取接收机信息，再让接收机进入 Boot 模式。\n'
        '升级过程中请不要断电，也不要离开升级页面。\n'
        '若页面提示失败，请重新连接接收机并再次尝试。',
  ),
];
