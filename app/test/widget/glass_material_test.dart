import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/core/widgets/glass_surface.dart';

void main() {
  testWidgets('glass passes scene color; accessibility material obscures it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(200, 100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<int> sceneDifference({required bool highContrast}) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              highContrast: highContrast,
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: key,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Expanded(child: ColoredBox(color: Colors.red)),
                      Expanded(child: ColoredBox(color: Colors.blue)),
                    ],
                  ),
                  const Center(
                    child: SizedBox(
                      width: 180,
                      height: 80,
                      child: GlassSurface(
                        blur: true,
                        clear: true,
                        padding: EdgeInsets.zero,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      var difference = 0;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final left = (50 * 200 + 50) * 4;
        final right = (50 * 200 + 150) * 4;
        difference =
            (bytes.getUint8(left) - bytes.getUint8(right)).abs() +
            (bytes.getUint8(left + 2) - bytes.getUint8(right + 2)).abs();
        image.dispose();
      });
      return difference;
    }

    expect(await sceneDifference(highContrast: false), greaterThan(100));
    expect(await sceneDifference(highContrast: true), lessThan(3));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('touch feedback does not delay the action', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Center(
          child: GlassSurface(
            blur: true,
            onTap: () => calls++,
            child: const Text('Open map'),
          ),
        ),
      ),
    );
    final touch = await tester.startGesture(
      tester.getCenter(find.text('Open map')),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(calls, 0);
    await touch.up();
    await tester.pump();
    expect(calls, 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
