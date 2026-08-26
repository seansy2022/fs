## Why

控制页当前以每秒一次的节奏显示 3、2、1，用户需要更快进入可操作状态，同时仍需保留倒计时期间禁止输出控制帧的安全约束。

## What Changes

- 将控制页 3、2、1 倒计时的总时长从 3 秒缩短为 1.5 秒。
- 每个数字保持可见 0.5 秒，倒计时结束后再恢复控制会话和连接后的控制循环。
- 更新 Widget 测试，校验数字切换节奏以及 1.5 秒结束时机。

## Capabilities

### New Capabilities

- `control-page-countdown`: 控制页安全倒计时的显示节奏和完成后解锁行为。

### Modified Capabilities

<!-- 无现有 OpenSpec capability 需要修改。 -->

## Impact

- 受影响代码：`lib/src/features/control/view/control_page.dart`。
- 受影响测试：`test/control_page_test.dart`。
- 不涉及蓝牙协议、公共 API 或新增依赖。
