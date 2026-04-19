/// UI-specific display models for rc_ui components.
/// These are display-only models decoupled from any app domain types.

/// A display model representing a Bluetooth device in the device list.
class UiBluetoothDevice {
  const UiBluetoothDevice({
    required this.id,
    required this.name,
    required this.connected,
  });

  final int id;
  final String name;
  final bool connected;
}

/// A tab item for the bottom navigation bar.
class UiNavTab {
  const UiNavTab({
    required this.label,
    required this.iconAsset,
    required this.activeIconAsset,
    this.isActive = false,
  });

  final String label;
  final String iconAsset;
  final String activeIconAsset;
  final bool isActive;
}
