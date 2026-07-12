# controller_app 文件组织规范

## 1. 维护规则（强制）
1. 新增、删除、重命名目录或核心文件时，必须同步更新本文件。
2. 全局级 `provider` 统一放在 `lib/src/provider/`，禁止分散到其他根目录。
3. 页面统一放在各 feature 的 `view/` 目录，禁止新建 `pages/` 目录。
4. 资源统一放在 `assets/`，禁止新增业务资源到 `lib/` 根目录。
5. 单文件代码原则上不超过 200 行；超限时优先按 `controller/provider/widget/model` 拆分。
6. 分层职责必须保持高内聚低耦合：
   - `view` 负责页面组装与交互绑定
   - `controller` 负责流程编排
   - `provider` 负责状态管理与状态派生
   - `widget` 负责可复用视图组件
   - `model` 负责数据结构与领域模型

## 2. 目录模板（新增功能按此落位）
```text
lib/src/features/<feature_name>/
  view/
  widget/
  controller/
  model/

lib/src/provider/
  app_provider.dart
  bluetooth_provider.dart
  control_provider.dart
  device_status_provider.dart
  settings_provider.dart
```

## 3. 命名规范
1. 页面文件：`*_page.dart`，存放在 `view/`。
2. Provider 文件：`*_provider.dart`，存放在 `lib/src/provider/`。
3. 状态类型：`XxxState`。
4. 控制器类型：`XxxController` 或 `XxxNotifier`。
5. 文档文件统一小写英文命名，避免 `1.MD`、`需求.MD` 这类混合风格。

## 4. 当前项目结构（2026-05-31）

### 根目录
- `pubspec.yaml`：依赖与资源声明。
- `analysis_options.yaml`：静态检查规则。
- `AGENTS.md`：协作规则。
- `File.md`：本规范文件。
- `assets/`：统一资源目录。
- `assets/icons/reconnect_loading.svg`：断线自动重连的循环加载图标。
- `assets/firmware/`：随 App 打包的接收机固件升级包。
- `doc/`：需求、协议、问题记录。
- `test/`：单元与 Widget 测试。
- `test/fakes/`：测试用蓝牙仓库等替身对象，避免测试文件膨胀。
- `test/home_reconnect_flow_test.dart`：首页自动扫描上次蓝牙设备的启动链路测试。
- `test/global_reconnect_provider_test.dart`：全局断线自动重连与取消链路测试。
- `test/reconnect_overlay_view_test.dart`：重连遮罩在小尺寸屏幕下的布局测试。
- `test/tank_mixing_page_test.dart`：履带混控开关与数值输入禁用状态测试。

### lib/src 分层
- `app/`：应用装配与路由。
- `core/`：基础能力（常量、权限、基础 provider 出口）。
- `provider/`：全局状态 provider（统一入口）。
- `shared/`：跨 feature 复用组件。
- `features/`：按业务域拆分。

### features（页面统一使用 view）
- `features/startup/view/`：启动页。
- `features/home/view/`：首页。
- `features/bluetooth/view/`：设备列表、配对页。
- `features/control/view/`：控制页。
- `features/control/controllers/`：控制页状态编排与通道输出映射。
- `features/control/controllers/channel_output_mapper.dart`：CH1/CH2 百分比到 us 的分段映射工具。
- `features/control/controllers/tank_mixer.dart`：履带混控 CH1/CH2 差速输出计算与通道范围限制。
- `features/control/controllers/control_aux_runtime_store.dart`：控制页 CH3/CH4 辅助通道选择状态本地保存。
- `features/control/widgets/`：控制页复用组件（转向按钮、顶部辅助按钮组等）。
- `features/control/widgets/control_status_warning_text.dart`：控制页顶部居中报警提示文案。
- `features/settings/view/`：设置主页与子页。
- `features/settings/controllers/channel_value_constraints.dart`：通道设置低/高/中百分比输入范围约束。
- `features/settings/models/aux_channel_value_rules.dart`：CH3/CH4 辅助通道状态数量和值域规则。
- `features/settings/widgets/`：设置页复用组件（布局、切换项、数值弹窗、统一操作按钮）。
- `features/settings/widgets/numeric_input_field.dart`：数值弹窗内的统一输入框。
- `features/settings/widgets/numeric_input_value_formatter.dart`：数值弹窗固定负号显示与提交格式化工具。
- `features/settings/widgets/firmware_upgrade_progress_dialog.dart`：固件升级真实进度弹窗。
- `features/settings/widgets/firmware_upgrade_status_view.dart`：固件升级中/成功/失败统一状态视图。
- `features/settings/widgets/tank_mixing_panel.dart`：履带混控布局与方向输入按钮。
- `features/settings/widgets/tank_mixing_direction_controls.dart`：履带混控左右方向区与前后输入行组件。
- `features/settings/widgets/tank_mixing_value_control.dart`：履带混控数值按钮的禁用灰化和标签组件。
- `features/help/view/`：帮助页。

### provider（统一收口）
- `alert_audio_player.dart`：报警语音播放能力。
- `alert_message_provider.dart`：控制页报警文案显示状态。
- `app_settings_provider.dart`：设置状态。
- `battery_alert_provider.dart`：模型低电压报警监听与触发。
- `bluetooth_domain_provider.dart`：蓝牙扫描、连接、设备聚合状态。
- `global_reconnect_provider.dart`：全局断线后自动重连状态与重试流程。
- `control_provider.dart`：控制状态流转入口。
- `control_presentation_provider.dart`：控制页音效与动画展示状态。
- `effective_bluetooth_provider.dart`：统一真实蓝牙与模拟蓝牙的有效状态入口。
- `gyro_prompt_provider.dart`：陀螺仪输入映射状态。
- `race_sound_player.dart`：音效播放器能力。
- `receiver_ble_mode_provider.dart`：接收机退出蓝牙模式并断开连接的流程编排。
- `reconnect_alert_provider.dart`：断开/连上提示监听与触发。
- `signal_alert_provider.dart`：低模型信号报警监听与触发。
- `signal_strength_utils.dart`：RSSI 转信号百分比工具。
- `simulated_bluetooth_provider.dart`：未连接蓝牙时的模拟遥测数据。
- `voice.dart`：语音相关导出。

### core
- `app_vibration.dart`：统一震动工具。
- `receiver_device_view.dart`：蓝牙设备展示模型、设备名展示与扫描过滤规则。
- `shared/widgets/global_reconnect_overlay.dart`：全局断线自动重连 loading 与取消按钮。

## 5. 变更同步规则（执行清单）
1. 改目录前先改本文件中的目标结构与规则。
2. 代码迁移完成后，回查 import 与路由引用。
3. 完成后再次同步本文件“当前项目结构”章节。
4. 提交前检查：
   - 不存在 `features/*/pages`
   - 不存在 `features/*/providers`
   - 新增全局 provider 都在 `lib/src/provider/`
