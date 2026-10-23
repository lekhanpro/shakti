import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/app.dart';
import 'package:shakti/core/router/app_shell.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/core/widgets/glass_surface.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/panic/application/panic_controller.dart';
import 'package:shakti/features/panic/application/panic_view_state.dart';
import 'package:shakti/features/panic/presentation/sos_screen.dart';
import 'package:shakti/features/safety_map/presentation/safety_map_screen.dart';
import 'package:shakti/features/safety_map/presentation/map_basemap.dart';

import '../fakes/fakes.dart';

void main() {
  testWidgets(
    'map credits open accessible attribution links and close at 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: Fakes().overrides(),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 850),
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: SafetyMapScreen(showTiles: false),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final credit = find.text(
        MapBasemap.usesCarto
            ? '© OpenStreetMap, © CARTO'
            : '© OpenStreetMap contributors',
      );
      expect(
        tester
            .getSize(
              find.ancestor(of: credit, matching: find.byType(TextButton)),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(credit);
      await tester.pumpAndSettle();
      expect(find.text('Map attributions'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsWidgets);
      expect(
        find.text('© CARTO'),
        MapBasemap.usesCarto ? findsOneWidget : findsNothing,
      );
      expect(find.text('Routing: OSRM · FOSSGIS'), findsOneWidget);
      expect(find.text('Report a map issue'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Map attributions'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [400.0, 800.0]) {
    testWidgets(
      'shell preserves Guardian draft across navigation at ${width}dp',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = Fakes();
        f.settings.settings = const SafetySettings(onboardingComplete: true);
        await tester.pumpWidget(
          ProviderScope(overrides: f.overrides(), child: const ShaktiApp()),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        Future<void> select(String label) async {
          final dock = find.descendant(
            of: find.byType(ShaktiDock),
            matching: find.bySemanticsLabel(label),
          );
          await tester.tap(width < 760 ? dock : find.text(label).last);
          await tester.pump(const Duration(milliseconds: 300));
        }

        await select('Guardian');
        await tester.enterText(find.byType(TextField), 'Help me plan a walk');
        // Dismiss the software keyboard before using floating navigation.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await select('Shield');
        await select('Guardian');
        expect(find.text('Help me plan a walk'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets('compact dock keeps all semantic actions at 200% text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ShaktiDock(
                  selectedIndex: 0,
                  onSelected: (i) => selected = i,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (final label in ['Shield', 'Map', 'Escort', 'Guardian', 'Settings']) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.rect.width, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.bySemanticsLabel('Guardian'));
    expect(selected, 3, reason: 'Navigation must not wait for its animation.');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('high contrast glass removes the backdrop filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: const GlassSurface(
            blur: true,
            child: Text('Readable material'),
          ),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets(
    '320dp large-text countdown keeps Cancel visible and aborts without SMS',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = Fakes();
      final container = ProviderContainer(overrides: f.overrides());
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: SosScreen(),
            ),
          ),
        ),
      );
      unawaited(
        container
            .read(panicControllerProvider.notifier)
            .trigger(TriggerSource.hudTap),
      );
      await tester.pump();
      await tester.pump();
      final cancel = find.text('Cancel');
      expect(tester.getRect(cancel).bottom, lessThanOrEqualTo(640));
      await tester.tap(cancel);
      await tester.pump();
      expect(container.read(panicControllerProvider).phase, PanicPhase.idle);
      expect(f.sms.sent, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
