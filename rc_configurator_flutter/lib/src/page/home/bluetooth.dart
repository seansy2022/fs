import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rc_ui/rc_ui.dart';

import 'package:rc_configurator_flutter/l10n/app_localizations.dart';
import '../../types.dart';
import '../startup_permission.dart';

class Bluetooth extends StatefulWidget {
  const Bluetooth({
    super.key,
    required this.settings,
    required this.onStartScan,
    required this.onToggleConnection,
  });

  final BluetoothSettings settings;
  final VoidCallback onStartScan;
  final ValueChanged<int> onToggleConnection;

  @override
  State<Bluetooth> createState() => _BluetoothState();
}

class _BluetoothState extends State<Bluetooth> {
  late Future<bool> _permissionFuture;
  bool _autoScanQueued = false;
  bool _didAutoStartScan = false;
  bool _showConnectFail = false;
  double _connectFailProgress = 0;
  bool _showConnectSuccess = false;
  Timer? _connectFailTimer;
  Timer? _connectSuccessTimer;

  @override
  void initState() {
    super.initState();
    _permissionFuture = _hasRequiredPermissions();
  }

  @override
  void didUpdateWidget(covariant Bluetooth oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justConnected =
        !oldWidget.settings.isConnected && widget.settings.isConnected;
    if (justConnected && !widget.settings.isConnecting) {
      _showConnectSuccessOverlay();
    }
    if (widget.settings.isConnecting) {
      _hideConnectSuccess();
      _hideConnectFail();
      return;
    }
    if (!widget.settings.isConnected) {
      _hideConnectSuccess();
    }
    if (widget.settings.isConnected) {
      _hideConnectFail();
      return;
    }
    final finishedConnecting =
        oldWidget.settings.isConnecting && !widget.settings.isConnecting;
    final hasError = (widget.settings.errorMessage ?? '').isNotEmpty;
    if (finishedConnecting && hasError) {
      final failProgress = BlueConnectingLoading.waitingProgressForStart(
        oldWidget.settings.connectingStartedAt,
      );
      _showConnectFailOverlay(progress: failProgress);
    }
  }

  @override
  void dispose() {
    _connectFailTimer?.cancel();
    _connectSuccessTimer?.cancel();
    super.dispose();
  }

  bool get _hasScanState {
    return widget.settings.isScanning || widget.settings.devices.isNotEmpty;
  }

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> _hasRequiredPermissions() async {
    final permissions = await permissionsForPlatform();
    if (permissions.isEmpty) return true;
    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );
    return statuses.every((status) => status.isGranted || status.isLimited);
  }

  void _syncDisconnectedWhenAdapterOff(bool isAdapterOn) {
    if (isAdapterOn || !widget.settings.isConnected) return;
    final connected = widget.settings.devices.where(
      (device) => device.connected,
    );
    if (connected.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onToggleConnection(connected.first.id);
    });
  }

  void _autoStartScan() {
    if (_didAutoStartScan || _autoScanQueued) return;
    _autoScanQueued = true;
    _didAutoStartScan = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onStartScan();
    });
  }

  Widget _buildBluetoothBody({required bool isAdapterOn}) {
    final l10n = AppLocalizations.of(context)!;
    if (!isAdapterOn) {
      _autoScanQueued = false;
      return _buildDisabledView(
        onEnable: _enableBluetoothAndScan,
        title: l10n.noDevices,
        subtitle: l10n.bluetoothOff,
        buttonText: l10n.turnOnBluetooth,
      );
    }
    if (!_hasScanState) {
      _autoStartScan();
      return _buildDisabledView(
        onEnable: widget.onStartScan,
        title: l10n.noDevices,
        subtitle: l10n.tapToScan,
        buttonText: l10n.startScanning,
      );
    }
    if (widget.settings.devices.isEmpty) {
      return BluetoothSearchingView(
        titleText: l10n.searching,
        subtitleText: l10n.searchingNearby,
      );
    }
    final uiDevices = widget.settings.devices
        .map(
          (d) =>
              UiBluetoothDevice(id: d.id, name: d.name, connected: d.connected),
        )
        .toList();
    return BluetoothListView(
      devices: uiDevices,
      isScanning: widget.settings.isScanning,
      onTapDevice: widget.onToggleConnection,
      searchingText: l10n.searching,
      connectedLabel: l10n.connected,
      disconnectedLabel: l10n.disconnected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final hasPermissions = snapshot.data ?? false;
        if (!hasPermissions) {
          final l10n = AppLocalizations.of(context)!;
          return _buildWithConnectFeedback(
            _buildDisabledView(
              onEnable: _requestPermissions,
              title: l10n.permissionNotGranted,
              subtitle: defaultTargetPlatform == TargetPlatform.iOS
                  ? l10n.grantLocationBtPermission
                  : l10n.grantBtPermission,
              buttonText: l10n.grantPermission,
            ),
          );
        }
        if (!_isMobilePlatform) {
          return _buildWithConnectFeedback(
            _buildBluetoothBody(isAdapterOn: true),
          );
        }
        return StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: FlutterBluePlus.adapterStateNow,
          builder: (context, stateSnapshot) {
            final isAdapterOn = stateSnapshot.data == BluetoothAdapterState.on;
            _syncDisconnectedWhenAdapterOff(isAdapterOn);
            return _buildWithConnectFeedback(
              _buildBluetoothBody(isAdapterOn: isAdapterOn),
            );
          },
        );
      },
    );
  }

  Widget _buildDisabledView({
    required VoidCallback onEnable,
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: h * 300 / 1624,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: AppFonts.s20,
                        fontWeight: AppFonts.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7DA2CE),
                        fontSize: AppFonts.s14,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: h * 254 / 1624,
                child: PrimaryButton(
                  onTap: onEnable,
                  enabled: true,
                  type: PrimaryButtonType.primary,
                  text: buttonText,
                  margin: EdgeInsets.symmetric(horizontal: w * 32 / 750),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWithConnectFeedback(Widget child) {
    final l10n = AppLocalizations.of(context)!;
    final showConnecting = widget.settings.isConnecting;
    final showSuccess = !showConnecting && _showConnectSuccess;
    final showFail = !showConnecting && !showSuccess && _showConnectFail;
    if (!showConnecting && !showSuccess && !showFail) return child;
    return Stack(
      children: [
        Positioned.fill(child: child),
        const Positioned.fill(
          child: ModalBarrier(dismissible: false, color: Color(0x66001024)),
        ),
        if (showConnecting)
          Center(
            child: BlueConnectingLoading(
              connectingStartedAt: widget.settings.connectingStartedAt,
              text: l10n.connecting,
            ),
          )
        else if (showSuccess)
          Center(child: BlueConnectSuccessLoading(text: l10n.connectedSuccess))
        else
          Center(child: BlueConnectFailLoading(progress: _connectFailProgress, text: l10n.connectFailed)),
      ],
    );
  }

  void _showConnectFailOverlay({required double progress}) {
    _connectFailTimer?.cancel();
    _hideConnectSuccess();
    setState(() {
      _connectFailProgress = progress;
      _showConnectFail = true;
    });
    _connectFailTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showConnectFail = false);
    });
  }

  void _hideConnectFail() {
    _connectFailTimer?.cancel();
    if (!_showConnectFail) return;
    setState(() => _showConnectFail = false);
  }

  void _showConnectSuccessOverlay() {
    _connectSuccessTimer?.cancel();
    setState(() => _showConnectSuccess = true);
    _connectSuccessTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showConnectSuccess = false);
    });
  }

  void _hideConnectSuccess() {
    _connectSuccessTimer?.cancel();
    if (!_showConnectSuccess) return;
    setState(() => _showConnectSuccess = false);
  }

  Future<void> _requestPermissions() async {
    await requestStartupPermissions(context);
    try {
      final hasPermissions = await _hasRequiredPermissions();
      if (!mounted) return;
      setState(() {
        _permissionFuture = Future.value(hasPermissions);
      });
      if (hasPermissions) {
        widget.onStartScan();
      }
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _enableBluetoothAndScan() async {
    if (!_isMobilePlatform) {
      widget.onStartScan();
      return;
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await FlutterBluePlus.turnOn(timeout: 15);
      }
    } on Object {
      widget.onStartScan();
      return;
    }
    widget.onStartScan();
  }
}
