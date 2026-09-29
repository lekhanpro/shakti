library;

import '../entities/entities.dart';

abstract interface class ContactRepository {
  Stream<List<EmergencyContact>> watchAll();
  Future<List<EmergencyContact>> active();
  Future<void> upsert(EmergencyContact c);
  Future<void> delete(String id);
}

abstract interface class IncidentRepository {
  Stream<List<Incident>> watchAll();
  Future<Incident?> byId(String id);
  Future<Incident?> latestOpen();
  Future<void> save(Incident i);
  Future<void> addBreadcrumb(Breadcrumb b);
  Future<List<Breadcrumb>> breadcrumbs(String incidentId);
}

abstract interface class SettingsRepository {
  Future<SafetySettings> load();
  Future<void> save(SafetySettings s);
  Stream<SafetySettings> watch();
}

abstract interface class HavenCacheRepository {
  Future<List<SafeHaven>> cached();
  Future<void> replaceAll(List<SafeHaven> havens);
}

abstract interface class SafePlaceRepository {
  Stream<List<SafePlace>> watchAll();
  Future<List<SafePlace>> all();
  Future<void> upsert(SafePlace p);
  Future<void> delete(String id);
}

abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchAll();
  Future<void> add(ChatMessage m);
  Future<void> clear();
}
