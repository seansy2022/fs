import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/provider/startup_provider.dart';

void main() {
  test('startup initialize sets app ready after 1 second', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(startupProvider.notifier);
    expect(container.read(startupProvider).isReady, false);
    await notifier.initialize();

    final state = container.read(startupProvider);
    expect(state.isBooting, false);
    expect(state.isReady, true);
  });

  test('markPermissionsHandled updates state once', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(startupProvider.notifier);
    expect(container.read(startupProvider).permissionsHandled, false);
    notifier.markPermissionsHandled();
    notifier.markPermissionsHandled();

    expect(container.read(startupProvider).permissionsHandled, true);
  });
}
