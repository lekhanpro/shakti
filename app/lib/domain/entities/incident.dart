enum TriggerSource {
  hudTap('HUD_TAP', 'SOS button'),
  triplePower('TRIPLE_POWER', 'Power button x3'),
  volumeTriple('VOLUME_TRIPLE', 'Volume key x3'),
  shake('SHAKE', 'Shake or fall'),
  voiceKeyword('VOICE_KEYWORD', 'Voice keyword'),
  timerExpired('TIMER_EXPIRED', 'Escort timer expired'),
  decoyPin('DECOY_PIN', 'Duress PIN');

  const TriggerSource(this.wire, this.label);

  /// Value stored in SQLite / Postgres.
  final String wire;
  final String label;

  static TriggerSource fromWire(String v) =>
      TriggerSource.values.firstWhere((e) => e.wire == v, orElse: () => TriggerSource.hudTap);
}

enum IncidentStatus {
  countdown('COUNTDOWN'),
  active('ACTIVE'),
  resolved('RESOLVED'),
  falseAlarm('FALSE_ALARM');

  const IncidentStatus(this.wire);
  final String wire;

  static IncidentStatus fromWire(String v) =>
      IncidentStatus.values.firstWhere((e) => e.wire == v, orElse: () => IncidentStatus.active);
}

class Incident {
  const Incident({
    required this.id,
    required this.source,
    required this.status,
    required this.createdAt,
    required this.shareToken,
    this.lat,
    this.lng,
    this.address,
    this.batteryLevel,
    this.smsDispatched = false,
    this.cloudDispatched = false,
    this.audioPath,
    this.resolvedAt,
    this.covert = false,
    this.synced = false,
  });

  final String id;
  final TriggerSource source;
  final IncidentStatus status;
  final DateTime createdAt;

  /// Random secret embedded in the guardian tracker link.
  final String shareToken;
  final double? lat;
  final double? lng;
  final String? address;
  final int? batteryLevel;
  final bool smsDispatched;
  final bool cloudDispatched;
  final String? audioPath;
  final DateTime? resolvedAt;

  /// Raised silently (decoy PIN / stealth): no siren, no haptics, no visible UI.
  final bool covert;
  final bool synced;

  bool get isOpen => status == IncidentStatus.active || status == IncidentStatus.countdown;

  Incident copyWith({
    IncidentStatus? status,
    double? lat,
    double? lng,
    String? address,
    int? batteryLevel,
    bool? smsDispatched,
    bool? cloudDispatched,
    String? audioPath,
    DateTime? resolvedAt,
    bool? synced,
  }) =>
      Incident(
        id: id,
        source: source,
        status: status ?? this.status,
        createdAt: createdAt,
        shareToken: shareToken,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        address: address ?? this.address,
        batteryLevel: batteryLevel ?? this.batteryLevel,
        smsDispatched: smsDispatched ?? this.smsDispatched,
        cloudDispatched: cloudDispatched ?? this.cloudDispatched,
        audioPath: audioPath ?? this.audioPath,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        covert: covert,
        synced: synced ?? this.synced,
      );

  /// Supabase `incident_reports` row shape.
  Map<String, Object?> toRemoteJson() => {
        'id': id,
        'trigger_source': source.wire,
        'status': status.wire,
        'latitude': lat,
        'longitude': lng,
        'street_address': address,
        'battery_level': batteryLevel,
        'carrier_sms_dispatched': smsDispatched,
        'share_token': shareToken,
        'covert': covert,
        'resolved_at': resolvedAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Incident &&
      other.id == id &&
      other.status == status &&
      other.lat == lat &&
      other.lng == lng &&
      other.address == address &&
      other.smsDispatched == smsDispatched &&
      other.cloudDispatched == cloudDispatched &&
      other.audioPath == audioPath &&
      other.resolvedAt == resolvedAt &&
      other.synced == synced;

  @override
  int get hashCode => Object.hash(
      id, status, lat, lng, address, smsDispatched, cloudDispatched, audioPath, resolvedAt, synced);
}

class Breadcrumb {
  const Breadcrumb({
    required this.incidentId,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.speedKmh,
    this.accuracyM,
    this.battery,
  });

  final String incidentId;
  final double lat;
  final double lng;
  final DateTime recordedAt;
  final double? speedKmh;
  final double? accuracyM;
  final int? battery;

  Map<String, Object?> toRemoteJson() => {
        'incident_id': incidentId,
        'latitude': lat,
        'longitude': lng,
        'speed_kmh': speedKmh,
        'accuracy_meters': accuracyM,
        'battery_percentage': battery,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };
}
