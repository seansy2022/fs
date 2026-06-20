import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_configurator_flutter/src/page/selection_sheet.dart';

void main() {
  testWidgets('selection sheet keeps root bottom safe area', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 24),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showSelectionSheet(
                    context,
                    title: 'Title',
                    options: const ['A', 'B'],
                    selectedOption: 'A',
                    onOptionSelected: (_) {},
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final match = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(bottom: 24),
      ),
    );
    expect(match, findsOneWidget);
  });
}
