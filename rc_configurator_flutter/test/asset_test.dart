import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dump Asset Manifest', (WidgetTester tester) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final rcUiAssets = manifestMap.keys.where((key) => key.contains('rc_ui')).toList();
    debugPrint('==== ASSET KEYS ====');
    for (var key in rcUiAssets) {
      debugPrint(key);
    }
    debugPrint('====================');
  });
}
