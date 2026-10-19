import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/fir_template.dart';
import 'package:shakti/domain/entities/entities.dart';

void main() {
  final created = DateTime(2026, 9, 28, 21, 40);
  final now = DateTime(2026, 9, 29, 10, 15);

  Incident incident({String? address, double? lat, double? lng, String? audio}) => Incident(
        id: 'inc-42',
        source: TriggerSource.shake,
        status: IncidentStatus.resolved,
        createdAt: created,
        shareToken: 'tok',
        address: address,
        lat: lat,
        lng: lng,
        audioPath: audio,
      );

  final crumbs = [
    Breadcrumb(incidentId: 'inc-42', lat: 12.9716, lng: 77.5946, recordedAt: created),
    Breadcrumb(
        incidentId: 'inc-42',
        lat: 12.9730,
        lng: 77.5960,
        recordedAt: created.add(const Duration(seconds: 10))),
    Breadcrumb(
        incidentId: 'inc-42',
        lat: 12.9750,
        lng: 77.5990,
        recordedAt: created.add(const Duration(seconds: 20))),
  ];

  test('full report contains every key field', () {
    final out = FirTemplate.render(
      FirInput(
        incident: incident(
            address: 'MG Road, Bengaluru', lat: 12.9716, lng: 77.5946, audio: '/v/a.enc'),
        breadcrumbs: crumbs,
        complainantName: 'Priya Sharma',
        narrative: 'A man followed me from the metro and grabbed my arm.',
        accusedDescription: 'Tall, about 30, black jacket',
      ),
      now: now,
    );

    expect(out, contains('FIRST INFORMATION REPORT'));
    expect(out, contains('Station House Officer'));
    expect(out, contains('Priya Sharma'));
    expect(out, contains('28-09-2026'));
    expect(out, contains('21:40'));
    expect(out, contains('MG Road, Bengaluru'));
    expect(out, contains('12.971600, 77.594600'));
    expect(out, contains('A man followed me from the metro'));
    expect(out, contains('Tall, about 30, black jacket'));
    expect(out, contains('3 GPS points'));
    expect(out, contains('First point: 12.971600, 77.594600'));
    expect(out, contains('Last point: 12.975000, 77.599000'));
    expect(out, contains('Audio recording'));
    expect(out, contains('Bharatiya Nyaya Sanhita'));
    for (final s in ['74', '75', '78', '351']) {
      expect(out, contains('Section $s'));
    }
    expect(out, contains('free copy'));
    expect(out, contains('Zero FIR'));
    expect(out, contains('Signature'));
    expect(out, contains('29-09-2026'));
    expect(out, contains('inc-42'));
    expect(out, contains('Shake or fall'));
  });

  test('minimal input degrades gracefully', () {
    final out = FirTemplate.render(
      FirInput(
        incident: incident(),
        breadcrumbs: const [],
        complainantName: '  ',
        narrative: '',
      ),
      now: now,
    );
    expect(out, contains('Location not recorded'));
    expect(out, contains('No GPS trail recorded'));
    expect(out, contains('Not known'));
    expect(out, isNot(contains('Audio recording')));
    expect(out, contains('[Complainant name]'));
    expect(out, contains('[Describe what happened'));
    expect(out, contains('SHO'));
  });

  test('coordinates only when no address', () {
    final out = FirTemplate.render(
      FirInput(
        incident: incident(lat: 12.5, lng: 77.25),
        breadcrumbs: [crumbs.first],
        complainantName: 'Priya',
        narrative: 'x',
      ),
      now: now,
    );
    expect(out, contains('12.500000, 77.250000'));
    expect(out, contains('1 GPS point '));
    expect(out, contains('maps.google.com'));
  });

  test('defaults now to the current time', () {
    final out = FirTemplate.render(FirInput(
      incident: incident(),
      breadcrumbs: const [],
      complainantName: 'P',
      narrative: 'n',
    ));
    expect(out, contains('FIRST INFORMATION REPORT'));
  });
}
