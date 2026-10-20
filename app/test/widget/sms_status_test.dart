import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/panic/application/panic_view_state.dart';
import 'package:shakti/features/panic/presentation/sos_screen.dart';

import '../fakes/fakes.dart';

void main() {
  testWidgets('carrier handoff does not claim delivery or that help is coming', (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final f = Fakes();
    final incident = Incident(
      id: 'test', source: TriggerSource.hudTap,
      status: IncidentStatus.active, createdAt: f.clock.now(), shareToken: 'test-token',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: f.overrides(),
      child: MaterialApp(
        home: ActiveView(state: PanicViewState(
          phase: PanicPhase.active,
          startedAt: f.clock.now(),
          report: DispatchReport(
            incident: incident,
            channels: {DispatchChannel.sms: ChannelStatus.ok},
            smsRecipients: 2,
          ),
        )),
      ),
    ));
    expect(find.textContaining('Delivery is unconfirmed'), findsOneWidget);
    expect(find.textContaining('Help is on the way'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
