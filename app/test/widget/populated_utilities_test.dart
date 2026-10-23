import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/contacts/presentation/contacts_screen.dart';
import 'package:shakti/features/settings/presentation/safe_places_screen.dart';

import '../fakes/fakes.dart';

Future<void> _pumpNarrow(
  WidgetTester tester,
  Fakes fakes,
  Widget screen,
) async {
  tester.view.physicalSize = const Size(320, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakes.overrides(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 850),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'long contact names keep toggle and edit usable at 320 dp and 200% text',
    (tester) async {
      const name = 'Annapoorna Krishnamurthy Raghavendra';
      final fakes = Fakes();
      fakes.contacts.contacts = const [
        EmergencyContact(
          id: 'guardian-one',
          name: name,
          phone: '+919845012345',
          relationship: 'Campus Security',
        ),
        EmergencyContact(
          id: 'guardian-two',
          name: 'ಶ್ರೀಲಕ್ಷ್ಮಿ ಕುಟುಂಬದ ತುರ್ತು ಸಂಪರ್ಕ',
          phone: '+919845012346',
          priority: 2,
          isActive: false,
        ),
      ];
      await _pumpNarrow(tester, fakes, const ContactsScreen());
      expect(find.text('1 active contact'), findsOneWidget);

      final contact = find.byKey(const ValueKey('contact-guardian-one'));
      final toggle = find.descendant(
        of: contact,
        matching: find.byType(Switch),
      );
      await tester.scrollUntilVisible(
        toggle,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        fakes.contacts.contacts
            .firstWhere((item) => item.id == 'guardian-one')
            .isActive,
        isFalse,
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text(name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      final nameField = find.byKey(const ValueKey('contact-name'));
      expect(nameField, findsOneWidget);
      expect(tester.widget<TextFormField>(nameField).controller!.text, name);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'long safe-place names keep removal and confirmation usable at 320 dp and 200% text',
    (tester) async {
      const name =
          'Don Bosco Institute of Technology Main Entrance Meeting Point';
      final fakes = Fakes();
      fakes.safePlaces.places = const [
        SafePlace(id: 'college', name: name, point: GeoPoint(12.9716, 77.5946)),
        SafePlace(
          id: 'home',
          name: 'ಮನೆಯ ಹತ್ತಿರದ ಪರಿಚಿತ ಪ್ರವೇಶ ದ್ವಾರ',
          point: GeoPoint(12.973, 77.595),
        ),
      ];
      await _pumpNarrow(tester, fakes, const SafePlacesScreen());
      final remove = find.byTooltip('Remove $name');
      await tester.scrollUntilVisible(
        remove,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(remove).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(remove).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);

      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('Remove $name?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(fakes.safePlaces.places.map((place) => place.id), ['home']);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
