import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/home/presentation/home_screen.dart';

import '../fakes/fakes.dart';

Future<void> _home(
  WidgetTester tester,
  Fakes f, {
  double width = 400,
  double scale = 1,
}) async {
  final size = Size(width, 850);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: f.overrides(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: const HomeScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final width in [320.0, 400.0]) {
    testWidgets(
      'home remains readable while scrolling at ${width}px and 200% text',
      (tester) async {
        await _home(tester, Fakes(), width: width, scale: 2);
        expect(tester.takeException(), isNull);
        // ListView builds lower cards lazily, so inspect the whole screen.
        for (var i = 0; i < 12; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('1098'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'paused contacts still count toward the five saved contact slots',
    (tester) async {
      final f = Fakes();
      f.contacts.contacts = [
        for (var i = 0; i < 5; i++)
          EmergencyContact(
            id: '$i',
            name: 'Guardian $i',
            phone: '+91984501234$i',
            isActive: i == 0,
          ),
      ];
      await _home(tester, f);
      await tester.scrollUntilVisible(
        find.text('Your circle'),
        250,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('5 of 5 added · 1 active'), findsOneWidget);
    },
  );

  testWidgets('quick actions and helplines expose a screen reader tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _home(tester, Fakes());
      for (final label in [
        'Walk with me',
        'Fake call',
        'Share location',
        'Siren',
        'Call 112, Emergency',
        'Call 1098, Child helpline',
      ]) {
        final finder = find.bySemanticsLabel(label);
        await tester.scrollUntilVisible(
          finder,
          150,
          scrollable: find.byType(Scrollable),
        );
        expect(
          tester
              .getSemantics(finder)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
          reason: label,
        );
      }
    } finally {
      semantics.dispose();
    }
  });
}
