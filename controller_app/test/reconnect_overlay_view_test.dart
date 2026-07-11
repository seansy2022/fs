import 'package:controller_app/src/shared/widgets/reconnect_overlay_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('小尺寸屏幕中重连遮罩可滚动显示取消按钮', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ReconnectOverlayView(
                title: '正在重连',
                deviceName: 'R4P-123456',
                startedAt: DateTime(2026),
                actionLabel: '取消',
                onAction: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('取消'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Material), findsWidgets);
    expect(find.byType(DefaultTextStyle), findsWidgets);
    expect(tester.getSize(find.byType(TextButton)).height, 40);
    expect(tester.takeException(), isNull);
  });
}
