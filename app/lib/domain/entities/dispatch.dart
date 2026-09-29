import 'incident.dart';

/// Every independent channel the emergency pipeline fans out to.
enum DispatchChannel {
  localSave('Saved on phone'),
  location('Location fixed'),
  sms('SMS to contacts'),
  audio('Audio evidence'),
  siren('Siren'),
  cloud('Telegram and cloud'),
  tracking('Live tracking');

  const DispatchChannel(this.label);
  final String label;
}

enum ChannelStatus { pending, running, ok, failed, skipped }

class DispatchReport {
  const DispatchReport({
    required this.incident,
    required this.channels,
    this.smsRecipients = 0,
    this.notes = const {},
  });

  final Incident incident;
  final Map<DispatchChannel, ChannelStatus> channels;
  final int smsRecipients;

  /// Human-readable reason per channel (e.g. "No SIM", "Offline, queued").
  final Map<DispatchChannel, String> notes;

  ChannelStatus status(DispatchChannel c) => channels[c] ?? ChannelStatus.pending;

  DispatchReport withChannel(
    DispatchChannel c,
    ChannelStatus s, {
    String? note,
    Incident? incident,
    int? smsRecipients,
  }) =>
      DispatchReport(
        incident: incident ?? this.incident,
        channels: {...channels, c: s},
        smsRecipients: smsRecipients ?? this.smsRecipients,
        notes: note == null ? notes : {...notes, c: note},
      );
}

class EvidenceItem {
  const EvidenceItem({
    required this.path,
    required this.incidentId,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String path;
  final String incidentId;
  final DateTime createdAt;
  final int sizeBytes;
}

class FirInput {
  const FirInput({
    required this.incident,
    required this.breadcrumbs,
    required this.complainantName,
    required this.narrative,
    this.accusedDescription = '',
  });

  final Incident incident;
  final List<Breadcrumb> breadcrumbs;
  final String complainantName;
  final String narrative;
  final String accusedDescription;
}
