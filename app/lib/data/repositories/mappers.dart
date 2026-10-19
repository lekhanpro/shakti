import 'package:drift/drift.dart';

import '../../domain/entities/entities.dart';
import '../local/app_database.dart';

/// Row <-> entity conversions shared by the Drift repositories.

EmergencyContact contactFromRow(ContactRow r) => EmergencyContact(
      id: r.id,
      name: r.name,
      phone: r.phone,
      relationship: r.relationship,
      priority: r.priority,
      isActive: r.isActive,
    );

ContactsCompanion contactToRow(EmergencyContact c) => ContactsCompanion.insert(
      id: c.id,
      name: c.name,
      phone: c.phone,
      relationship: Value(c.relationship),
      priority: Value(c.priority),
      isActive: Value(c.isActive),
    );

Incident incidentFromRow(IncidentRow r) => Incident(
      id: r.id,
      source: TriggerSource.fromWire(r.source),
      status: IncidentStatus.fromWire(r.status),
      createdAt: r.createdAt,
      shareToken: r.shareToken,
      lat: r.lat,
      lng: r.lng,
      address: r.address,
      batteryLevel: r.batteryLevel,
      smsDispatched: r.smsDispatched,
      cloudDispatched: r.cloudDispatched,
      audioPath: r.audioPath,
      resolvedAt: r.resolvedAt,
      covert: r.covert,
      synced: r.synced,
    );

IncidentsCompanion incidentToRow(Incident i) => IncidentsCompanion.insert(
      id: i.id,
      source: i.source.wire,
      status: i.status.wire,
      createdAt: i.createdAt,
      shareToken: i.shareToken,
      lat: Value(i.lat),
      lng: Value(i.lng),
      address: Value(i.address),
      batteryLevel: Value(i.batteryLevel),
      smsDispatched: Value(i.smsDispatched),
      cloudDispatched: Value(i.cloudDispatched),
      audioPath: Value(i.audioPath),
      resolvedAt: Value(i.resolvedAt),
      covert: Value(i.covert),
      synced: Value(i.synced),
    );

Breadcrumb breadcrumbFromRow(BreadcrumbRow r) => Breadcrumb(
      incidentId: r.incidentId,
      lat: r.lat,
      lng: r.lng,
      recordedAt: r.recordedAt,
      speedKmh: r.speed,
      accuracyM: r.accuracy,
      battery: r.battery,
    );

BreadcrumbsCompanion breadcrumbToRow(Breadcrumb b) => BreadcrumbsCompanion.insert(
      incidentId: b.incidentId,
      lat: b.lat,
      lng: b.lng,
      recordedAt: b.recordedAt,
      speed: Value(b.speedKmh),
      accuracy: Value(b.accuracyM),
      battery: Value(b.battery),
    );

SafeHaven havenFromRow(HavenCacheRow r) => SafeHaven(
      id: r.id,
      name: r.name,
      category: HavenCategory.fromWire(r.category),
      point: GeoPoint(r.lat, r.lng),
      phone: r.phone,
      address: r.address,
      open24h: r.open24h,
    );

HavensCacheCompanion havenToRow(SafeHaven h, DateTime cachedAt) => HavensCacheCompanion.insert(
      id: h.id,
      name: h.name,
      category: h.category.wire,
      lat: h.point.lat,
      lng: h.point.lng,
      phone: Value(h.phone),
      address: Value(h.address),
      open24h: Value(h.open24h),
      cachedAt: cachedAt,
    );

SafePlace safePlaceFromRow(SafePlaceRow r) =>
    SafePlace(id: r.id, name: r.name, point: GeoPoint(r.lat, r.lng), radiusM: r.radiusM);

SafePlacesCompanion safePlaceToRow(SafePlace p) => SafePlacesCompanion.insert(
      id: p.id,
      name: p.name,
      lat: p.point.lat,
      lng: p.point.lng,
      radiusM: Value(p.radiusM),
    );

ChatMessage chatFromRow(ChatMessageRow r) => ChatMessage(
      id: r.id,
      role: ChatRole.values.firstWhere((e) => e.name == r.role, orElse: () => ChatRole.assistant),
      content: r.content,
      createdAt: r.createdAt,
    );

ChatMessagesCompanion chatToRow(ChatMessage m) => ChatMessagesCompanion.insert(
      id: m.id,
      role: m.role.name,
      content: m.content,
      createdAt: m.createdAt,
    );
