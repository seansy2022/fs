/// rc_ui — Shared UI component library and theme for RC configurator apps.
library rc_ui;

// ─── Core ────────────────────────────────────────────────────────────────────
export 'src/core/app_assets.dart';
export 'src/core/theme/app_theme.dart';
export 'src/core/models/ui_models.dart';

// ─── Elements (Atomic) ──────────────────────────────────────────────────────
// Button
export 'src/elements/button/rc_icon_button.dart';
export 'src/elements/button/rc_button.dart';
export 'src/elements/button/svg_button.dart';
export 'src/elements/button/primary_button.dart';
export 'src/elements/button/work_button.dart';
export 'src/elements/button/selectable_button.dart';

// Text
export 'src/elements/text/rc_text.dart';

// Icon
export 'src/elements/icon/svg_asset_tile.dart';
export 'src/elements/icon/half_size_svg_asset.dart';

// Container
export 'src/elements/container/panel.dart';
export 'src/elements/container/rc_divider.dart';

// ─── Components (Molecular) ─────────────────────────────────────────────────
// Cell
export 'src/components/cell/cell_button_widget.dart';
export 'src/components/cell/cell_switch_widget.dart';
export 'src/components/cell/cell_components.dart';
export 'src/components/cell/cell_rate_widget.dart';
export 'src/components/cell/cell_icon_widget.dart';
export 'src/components/cell/button_cell.dart';
export 'src/components/cell/cell.dart';
export 'src/components/cell/cell_icon_text_widget.dart';
export 'src/components/cell/cell_mode_widget.dart';

// Progress
export 'src/components/progress/item_button/item_button.dart';
export 'src/components/progress/named_control_progress_widget.dart';
export 'src/components/progress/progress_bar.dart';
export 'src/components/progress/sides_control_progress_widget.dart';

// Slider
export 'src/components/slider/curve_tabs.dart';
export 'src/components/slider/curve_slider.dart';

// Forms
export 'src/components/forms/switcher.dart';
export 'src/components/forms/segmented.dart';
export 'src/components/forms/rc_multi_toggle.dart';
export 'src/components/menu/menu.dart';

// Value Control
export 'src/components/value_control/svg_value_control.dart';
export 'src/components/value_control/control_value_widget.dart';

// ─── Features (Domain-Specific) ─────────────────────────────────────────────
// Dashboard
export 'src/features/dashboard/top/home_top_widget.dart';
export 'src/features/dashboard/four_lun_ratio_control.dart';
export 'src/features/dashboard/rate_chart.dart';
export 'src/features/dashboard/top_data.dart';
export 'src/features/dashboard/top.dart';
export 'src/features/dashboard/center/home_center_widget.dart';
export 'src/features/dashboard/rate_chart_painter.dart';
export 'src/features/dashboard/top_painter.dart';
export 'src/features/dashboard/home_metric.dart';
export 'src/features/dashboard/travel_control.dart';
export 'src/features/dashboard/four_lun_control.dart';
export 'src/features/dashboard/double_rate.dart';
export 'src/features/dashboard/failsafe_ch4_control.dart';
export 'src/features/dashboard/failsafe_control.dart';

// Bluetooth
export 'src/features/bluetooth/bluetooth_list_parts.dart';
export 'src/features/bluetooth/bluetooth_list_view.dart';
export 'src/features/bluetooth/bluetooth_searching_view.dart';

// Drive
export 'src/features/drive/layout/drive_mode_option.dart';
export 'src/features/drive/layout/drive_layout.dart';
export 'src/features/drive/layout/drive_mode_row.dart';
export 'src/features/drive/drive_mixing_control.dart';
export 'src/features/drive/brake_mixing_control.dart';

// Mixing (ex-hunkong)
export 'src/features/mixing/tank_control.dart';
export 'src/features/mixing/mixing_channel_row.dart';
export 'src/features/mixing/tank_control_parts.dart';
export 'src/features/mixing/four_c_layout_option.dart';
export 'src/features/mixing/four_c_layout_grid.dart';

// Control
export 'src/features/control/control.dart';
export 'src/features/controller_buttons/rc_drive_mode_switch.dart';
export 'src/features/controll_sider/rc_controll_sider.dart';

// ─── Layout ─────────────────────────────────────────────────────────────────
// Shell
export 'src/layout/shell/top_drawer.dart';
export 'src/layout/shell/top_draw_nodes.dart';
export 'src/layout/shell/top_draw_base.dart';
export 'src/layout/shell/app_shell.dart';
export 'src/layout/shell/section_title.dart';

// Navigation
export 'src/layout/nav/nav.dart';

// Tab Bar
export 'src/layout/tabbar/tabbar.dart';

// ─── Overlay ────────────────────────────────────────────────────────────────
// Dialogs - Loading
export 'src/overlay/dialogs/loading/blue_connect_fail_loading.dart';
export 'src/overlay/dialogs/loading/blue_connecting_loading.dart';
export 'src/overlay/dialogs/loading/blue_connect_success_loading.dart';
export 'src/overlay/dialogs/loading/blue_loading_base.dart';
export 'src/overlay/dialogs/loading/blue_loading.dart';

// Dialogs - Alert
export 'src/overlay/dialogs/alert/alert_widget.dart';
export 'src/overlay/dialogs/alert/alert_model_widget.dart';
export 'src/overlay/dialogs/alert/alert_input_widget.dart';
export 'src/overlay/dialogs/alert/alert_blue_widget.dart';
export 'src/overlay/dialogs/alert/alert_icon_widget.dart';
export 'src/overlay/dialogs/alert/alert_list_dialog.dart';
