# rc_configurator_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Harness 工程

- 智能体规则：`AGENTS.md`
- Harness 文档：`docs/engineering/harness/README.md`
- 任务模板：`docs/engineering/harness/task_template.md`
- 预检脚本：`tool/harness/preflight.sh`

## Link Env（BLE / Mock）

通过 `--dart-define=RC_LINK_MODE=<mode>` 配置链路实现：

- `ble`（默认）：真实蓝牙链路（`FlutterBlueTransport`）
- `mock`：协议级 Mock 数据链路（`MockProtocolLinkTransport`）
- `usb`：预留（当前为未实现占位）

示例：

```bash
flutter run --dart-define=RC_LINK_MODE=mock
```

日志开关（默认开启）：

- `RC_LINK_LOG`：传输层日志（扫描、连接、发包、收包）
- `RC_PROTOCOL_LOG`：协议层日志（请求、应答、解帧、重试）
- `RC_MOCK_LOG`：Mock 传输日志（mock 读写与 A1/A2 推送）

示例：

```bash
flutter run \
  --dart-define=RC_LINK_MODE=mock \
  --dart-define=RC_LINK_LOG=true \
  --dart-define=RC_PROTOCOL_LOG=true \
  --dart-define=RC_MOCK_LOG=true
```
