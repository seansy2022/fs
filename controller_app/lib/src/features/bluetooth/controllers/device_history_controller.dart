import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rc_c_ble/rc_c_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RememberedReceiver {
  const RememberedReceiver({
    required this.remoteId,
    required this.name,
    required this.lastUsedAt,
  });

  final String remoteId;
  final String name;
  final DateTime lastUsedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'remoteId': remoteId,
      'name': name,
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  factory RememberedReceiver.fromJson(Map<String, Object?> json) {
    return RememberedReceiver(
      remoteId: json['remoteId']! as String,
      name: json['name']! as String,
      lastUsedAt:
          DateTime.tryParse(json['lastUsedAt']! as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class DeviceHistoryController extends StateNotifier<List<RememberedReceiver>> {
  DeviceHistoryController() : super(const <RememberedReceiver>[]) {
    _load();
  }

  static const _storageKey = 'controller_app.remembered_receivers.v1';

  Future<void> rememberDevice(ReceiverScanDevice device) async {
    final updated = <RememberedReceiver>[
      RememberedReceiver(
        remoteId: device.remoteId,
        name: device.name,
        lastUsedAt: DateTime.now(),
      ),
      for (final entry in state)
        if (entry.remoteId != device.remoteId) entry,
    ];
    state = updated.take(10).toList(growable: false);
    await _save();
  }

  Future<void> removeDevice(String remoteId) async {
    state = state
        .where((device) => device.remoteId != remoteId)
        .toList(growable: false);
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .whereType<Map<String, dynamic>>()
          .map(RememberedReceiver.fromJson)
          .toList(growable: false);
    } catch (_) {
      state = const <RememberedReceiver>[];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(
        state.map((device) => device.toJson()).toList(growable: false),
      ),
    );
  }
}
