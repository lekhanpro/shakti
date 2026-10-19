/// Offline plain-text FIR (First Information Report) draft.
///
/// Used when the cloud drafting service is unavailable. Cites the Bharatiya
/// Nyaya Sanhita (BNS) 2023 sections most relevant to street harassment and
/// lists the complainant's rights under the BNSS.
library;

import '../entities/dispatch.dart';
import '../entities/geo_point.dart';

abstract final class FirTemplate {
  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _date(DateTime t) => '${_two(t.day)}-${_two(t.month)}-${t.year}';
  static String _time(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';
  static String _coords(double lat, double lng) =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

  static String render(FirInput input, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final inc = input.incident;
    final name = input.complainantName.trim().isEmpty
        ? '[Complainant name]'
        : input.complainantName.trim();
    final narrative = input.narrative.trim().isEmpty
        ? '[Describe what happened, in your own words, in the order it happened]'
        : input.narrative.trim();
    final accused =
        input.accusedDescription.trim().isEmpty ? 'Not known' : input.accusedDescription.trim();

    final address = inc.address?.trim() ?? '';
    final hasCoords = inc.lat != null && inc.lng != null;
    final place = StringBuffer();
    if (address.isNotEmpty) place.writeln('Place: $address');
    if (hasCoords) {
      place
        ..writeln('Coordinates: ${_coords(inc.lat!, inc.lng!)}')
        ..writeln('Map: ${GeoPoint(inc.lat!, inc.lng!).mapsUrl}');
    }
    if (address.isEmpty && !hasCoords) place.writeln('Place: Location not recorded');

    final crumbs = [...input.breadcrumbs]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final evidence = StringBuffer();
    if (crumbs.isEmpty) {
      evidence.writeln('- No GPS trail recorded.');
    } else {
      final n = crumbs.length;
      final first = crumbs.first;
      final last = crumbs.last;
      evidence
        ..writeln('- GPS trail: $n GPS point${n == 1 ? '' : 's'} recorded between '
            '${_time(first.recordedAt)} and ${_time(last.recordedAt)} on ${_date(first.recordedAt)}.')
        ..writeln('  First point: ${_coords(first.lat, first.lng)}')
        ..writeln('  Last point: ${_coords(last.lat, last.lng)}');
    }
    if (inc.audioPath != null && inc.audioPath!.isNotEmpty) {
      evidence.writeln('- Audio recording captured on my phone during the incident '
          '(encrypted; available on request).');
    }

    return '''
FIRST INFORMATION REPORT (DRAFT)
(Under Section 173, Bharatiya Nagarik Suraksha Sanhita, 2023)

To,
The Station House Officer (SHO),
[Police station name]

Date: ${_date(today)}

Subject: Complaint regarding an incident on ${_date(inc.createdAt)} at ${_time(inc.createdAt)}

1. Complainant
Name: $name
Contact: [Phone number]
Address: [Your address]

2. Date and time of occurrence
${_date(inc.createdAt)} at ${_time(inc.createdAt)}

3. Place of occurrence
${place.toString().trimRight()}

4. Details of the incident
$narrative

5. Description of the accused
$accused

6. Evidence available
${evidence.toString().trimRight()}
- Shakti incident reference: ${inc.id} (alert raised via: ${inc.source.label})

7. Possible offences (Bharatiya Nyaya Sanhita, 2023)
- Section 74: Assault or criminal force to a woman with intent to outrage her modesty
- Section 75: Sexual harassment
- Section 78: Stalking
- Section 351: Criminal intimidation
(The officer will decide the final sections based on the facts.)

I request you to register an FIR and take necessary action.

Your rights:
- You are entitled to a free copy of the FIR once it is registered.
- A Zero FIR can be filed at any police station, regardless of where the incident happened.
- If the station refuses to register it, you may send it to the Superintendent of Police.

Signature: ____________________
Name: $name
Date: ${_date(today)}
''';
  }
}
