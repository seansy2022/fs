import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'bluetooth_log_types.dart';

export 'bluetooth_log_types.dart';

const _dbName = 'rc_bluetooth_logs.db';
const _logTable = 'bluetooth_logs';
const _settingTable = 'bluetooth_log_settings';
const _enabledKey = 'enabled';
const _maxRows = 1000;

class SqfliteBluetoothLogStore implements BluetoothLogStore {
  Database? _db;
  Future<Database>? _opening;
  bool _enabled = false;
  bool _loadedEnabled = false;
  bool _disabled = false;

  @override
  Future<void> init() async {
    await _runSafe(() async {
      await _database();
      await _loadEnabled();
    });
  }

  @override
  Future<bool> isEnabled() async {
    if (_disabled) return false;
    if (!_loadedEnabled) await _runSafe(_loadEnabled);
    return !_disabled && _enabled;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _runSafe(() async {
      final db = await _database();
      _enabled = enabled;
      _loadedEnabled = true;
      await db.insert(_settingTable, {
        'key': _enabledKey,
        'value': enabled ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> append({
    required String direction,
    required String command,
    required String dataText,
  }) async {
    if (_disabled || !await isEnabled()) return;
    await _runSafe(() async {
      final db = await _database();
      await db.insert(_logTable, {
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
        'direction': direction,
        'command': command,
        'data_text': dataText,
      });
      await db.rawDelete(
        'DELETE FROM $_logTable WHERE id NOT IN '
        '(SELECT id FROM $_logTable ORDER BY id DESC LIMIT ?)',
        [_maxRows],
      );
    });
  }

  @override
  Future<List<BluetoothLogEntry>> listAllAsc() async {
    if (_disabled) return const <BluetoothLogEntry>[];
    try {
      final db = await _database();
      final rows = await db.query(
        _logTable,
        orderBy: 'timestamp_ms ASC, id ASC',
      );
      return rows
          .map(
            (e) => BluetoothLogEntry(
              id: (e['id'] as num).toInt(),
              timestampMs: (e['timestamp_ms'] as num).toInt(),
              direction: (e['direction'] as String?) ?? '',
              command: (e['command'] as String?) ?? '',
              dataText: (e['data_text'] as String?) ?? '',
            ),
          )
          .toList(growable: false);
    } catch (_) {
      _disable();
      return const <BluetoothLogEntry>[];
    }
  }

  Future<Database> _database() async {
    if (_disabled) throw StateError('bluetooth log store disabled');
    final existing = _db;
    if (existing != null) return existing;
    final opening = _opening;
    if (opening != null) return opening;
    _opening = _openDb();
    try {
      final db = await _opening!;
      _db = db;
      return db;
    } catch (_) {
      _disable();
      rethrow;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _openDb() async {
    final fullPath = path.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE $_logTable('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'timestamp_ms INTEGER NOT NULL,'
          'direction TEXT NOT NULL,'
          'command TEXT NOT NULL,'
          'data_text TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE $_settingTable('
          'key TEXT PRIMARY KEY,'
          'value INTEGER NOT NULL)',
        );
        await db.insert(_settingTable, {'key': _enabledKey, 'value': 0});
      },
    );
  }

  Future<void> _loadEnabled() async {
    if (_loadedEnabled) return;
    final rows = await (await _database()).query(
      _settingTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_enabledKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      await (await _database()).insert(_settingTable, {
        'key': _enabledKey,
        'value': 0,
      });
      _enabled = false;
    } else {
      _enabled = ((rows.first['value'] as num?) ?? 0) > 0;
    }
    _loadedEnabled = true;
  }

  Future<void> _runSafe(Future<void> Function() run) async {
    if (_disabled) return;
    try {
      await run();
    } catch (_) {
      _disable();
    }
  }

  void _disable() {
    _disabled = true;
    _enabled = false;
    _loadedEnabled = true;
    _opening = null;
  }
}

final BluetoothLogStore bluetoothLogStore = SqfliteBluetoothLogStore();
