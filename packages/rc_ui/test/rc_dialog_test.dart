import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_ui/rc_ui.dart';

void main() {
  testWidgets('confirm dialog returns false when cancel is tapped', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await RcConfirmDialog.show(
                context,
                message: 'Save changes?',
                cancelText: 'Cancel',
                confirmText: 'Confirm',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('success dialog closes after its duration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => RcSuccessDialog.show(
              context,
              message: 'Saved',
              duration: const Duration(milliseconds: 100),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.byType(RcSuccessDialog), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(RcSuccessDialog), findsNothing);
  });

  testWidgets('confirm dialog supports an optional status icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => RcConfirmDialog.show(
              context,
              message: 'Warning',
              cancelText: 'No',
              confirmText: 'Yes',
              icon: const Icon(Icons.warning),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(tester.widget<RcDialogShell>(find.byType(RcDialogShell)).height, 200);
  });
}
