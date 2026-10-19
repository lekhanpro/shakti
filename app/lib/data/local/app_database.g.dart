// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts
    with TableInfo<$ContactsTable, ContactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Family'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    relationship,
    priority,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class ContactRow extends DataClass implements Insertable<ContactRow> {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final int priority;
  final bool isActive;
  const ContactRow({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.priority,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['relationship'] = Variable<String>(relationship);
    map['priority'] = Variable<int>(priority);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      relationship: Value(relationship),
      priority: Value(priority),
      isActive: Value(isActive),
    );
  }

  factory ContactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      relationship: serializer.fromJson<String>(json['relationship']),
      priority: serializer.fromJson<int>(json['priority']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'relationship': serializer.toJson<String>(relationship),
      'priority': serializer.toJson<int>(priority),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ContactRow copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    int? priority,
    bool? isActive,
  }) => ContactRow(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    relationship: relationship ?? this.relationship,
    priority: priority ?? this.priority,
    isActive: isActive ?? this.isActive,
  );
  ContactRow copyWithCompanion(ContactsCompanion data) {
    return ContactRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      priority: data.priority.present ? data.priority.value : this.priority,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('relationship: $relationship, ')
          ..write('priority: $priority, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, relationship, priority, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.relationship == this.relationship &&
          other.priority == this.priority &&
          other.isActive == this.isActive);
}

class ContactsCompanion extends UpdateCompanion<ContactRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> relationship;
  final Value<int> priority;
  final Value<bool> isActive;
  final Value<int> rowid;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.relationship = const Value.absent(),
    this.priority = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String id,
    required String name,
    required String phone,
    this.relationship = const Value.absent(),
    this.priority = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       phone = Value(phone);
  static Insertable<ContactRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? relationship,
    Expression<int>? priority,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (relationship != null) 'relationship': relationship,
      if (priority != null) 'priority': priority,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? relationship,
    Value<int>? priority,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('relationship: $relationship, ')
          ..write('priority: $priority, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncidentsTable extends Incidents
    with TableInfo<$IncidentsTable, IncidentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncidentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareTokenMeta = const VerificationMeta(
    'shareToken',
  );
  @override
  late final GeneratedColumn<String> shareToken = GeneratedColumn<String>(
    'share_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batteryLevelMeta = const VerificationMeta(
    'batteryLevel',
  );
  @override
  late final GeneratedColumn<int> batteryLevel = GeneratedColumn<int>(
    'battery_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _smsDispatchedMeta = const VerificationMeta(
    'smsDispatched',
  );
  @override
  late final GeneratedColumn<bool> smsDispatched = GeneratedColumn<bool>(
    'sms_dispatched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sms_dispatched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cloudDispatchedMeta = const VerificationMeta(
    'cloudDispatched',
  );
  @override
  late final GeneratedColumn<bool> cloudDispatched = GeneratedColumn<bool>(
    'cloud_dispatched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cloud_dispatched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _covertMeta = const VerificationMeta('covert');
  @override
  late final GeneratedColumn<bool> covert = GeneratedColumn<bool>(
    'covert',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("covert" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    status,
    createdAt,
    shareToken,
    lat,
    lng,
    address,
    batteryLevel,
    smsDispatched,
    cloudDispatched,
    audioPath,
    resolvedAt,
    covert,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incidents';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncidentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('share_token')) {
      context.handle(
        _shareTokenMeta,
        shareToken.isAcceptableOrUnknown(data['share_token']!, _shareTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_shareTokenMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('battery_level')) {
      context.handle(
        _batteryLevelMeta,
        batteryLevel.isAcceptableOrUnknown(
          data['battery_level']!,
          _batteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('sms_dispatched')) {
      context.handle(
        _smsDispatchedMeta,
        smsDispatched.isAcceptableOrUnknown(
          data['sms_dispatched']!,
          _smsDispatchedMeta,
        ),
      );
    }
    if (data.containsKey('cloud_dispatched')) {
      context.handle(
        _cloudDispatchedMeta,
        cloudDispatched.isAcceptableOrUnknown(
          data['cloud_dispatched']!,
          _cloudDispatchedMeta,
        ),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('covert')) {
      context.handle(
        _covertMeta,
        covert.isAcceptableOrUnknown(data['covert']!, _covertMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncidentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncidentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      shareToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_token'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      batteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_level'],
      ),
      smsDispatched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sms_dispatched'],
      )!,
      cloudDispatched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cloud_dispatched'],
      )!,
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      covert: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}covert'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $IncidentsTable createAlias(String alias) {
    return $IncidentsTable(attachedDatabase, alias);
  }
}

class IncidentRow extends DataClass implements Insertable<IncidentRow> {
  final String id;
  final String source;
  final String status;
  final DateTime createdAt;
  final String shareToken;
  final double? lat;
  final double? lng;
  final String? address;
  final int? batteryLevel;
  final bool smsDispatched;
  final bool cloudDispatched;
  final String? audioPath;
  final DateTime? resolvedAt;
  final bool covert;
  final bool synced;
  const IncidentRow({
    required this.id,
    required this.source,
    required this.status,
    required this.createdAt,
    required this.shareToken,
    this.lat,
    this.lng,
    this.address,
    this.batteryLevel,
    required this.smsDispatched,
    required this.cloudDispatched,
    this.audioPath,
    this.resolvedAt,
    required this.covert,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['share_token'] = Variable<String>(shareToken);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || batteryLevel != null) {
      map['battery_level'] = Variable<int>(batteryLevel);
    }
    map['sms_dispatched'] = Variable<bool>(smsDispatched);
    map['cloud_dispatched'] = Variable<bool>(cloudDispatched);
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    map['covert'] = Variable<bool>(covert);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  IncidentsCompanion toCompanion(bool nullToAbsent) {
    return IncidentsCompanion(
      id: Value(id),
      source: Value(source),
      status: Value(status),
      createdAt: Value(createdAt),
      shareToken: Value(shareToken),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      batteryLevel: batteryLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryLevel),
      smsDispatched: Value(smsDispatched),
      cloudDispatched: Value(cloudDispatched),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      covert: Value(covert),
      synced: Value(synced),
    );
  }

  factory IncidentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncidentRow(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      shareToken: serializer.fromJson<String>(json['shareToken']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      address: serializer.fromJson<String?>(json['address']),
      batteryLevel: serializer.fromJson<int?>(json['batteryLevel']),
      smsDispatched: serializer.fromJson<bool>(json['smsDispatched']),
      cloudDispatched: serializer.fromJson<bool>(json['cloudDispatched']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      covert: serializer.fromJson<bool>(json['covert']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'shareToken': serializer.toJson<String>(shareToken),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'address': serializer.toJson<String?>(address),
      'batteryLevel': serializer.toJson<int?>(batteryLevel),
      'smsDispatched': serializer.toJson<bool>(smsDispatched),
      'cloudDispatched': serializer.toJson<bool>(cloudDispatched),
      'audioPath': serializer.toJson<String?>(audioPath),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'covert': serializer.toJson<bool>(covert),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  IncidentRow copyWith({
    String? id,
    String? source,
    String? status,
    DateTime? createdAt,
    String? shareToken,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<int?> batteryLevel = const Value.absent(),
    bool? smsDispatched,
    bool? cloudDispatched,
    Value<String?> audioPath = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
    bool? covert,
    bool? synced,
  }) => IncidentRow(
    id: id ?? this.id,
    source: source ?? this.source,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    shareToken: shareToken ?? this.shareToken,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    address: address.present ? address.value : this.address,
    batteryLevel: batteryLevel.present ? batteryLevel.value : this.batteryLevel,
    smsDispatched: smsDispatched ?? this.smsDispatched,
    cloudDispatched: cloudDispatched ?? this.cloudDispatched,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    covert: covert ?? this.covert,
    synced: synced ?? this.synced,
  );
  IncidentRow copyWithCompanion(IncidentsCompanion data) {
    return IncidentRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      shareToken: data.shareToken.present
          ? data.shareToken.value
          : this.shareToken,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      address: data.address.present ? data.address.value : this.address,
      batteryLevel: data.batteryLevel.present
          ? data.batteryLevel.value
          : this.batteryLevel,
      smsDispatched: data.smsDispatched.present
          ? data.smsDispatched.value
          : this.smsDispatched,
      cloudDispatched: data.cloudDispatched.present
          ? data.cloudDispatched.value
          : this.cloudDispatched,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      covert: data.covert.present ? data.covert.value : this.covert,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncidentRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('shareToken: $shareToken, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('address: $address, ')
          ..write('batteryLevel: $batteryLevel, ')
          ..write('smsDispatched: $smsDispatched, ')
          ..write('cloudDispatched: $cloudDispatched, ')
          ..write('audioPath: $audioPath, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('covert: $covert, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    status,
    createdAt,
    shareToken,
    lat,
    lng,
    address,
    batteryLevel,
    smsDispatched,
    cloudDispatched,
    audioPath,
    resolvedAt,
    covert,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncidentRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.shareToken == this.shareToken &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.address == this.address &&
          other.batteryLevel == this.batteryLevel &&
          other.smsDispatched == this.smsDispatched &&
          other.cloudDispatched == this.cloudDispatched &&
          other.audioPath == this.audioPath &&
          other.resolvedAt == this.resolvedAt &&
          other.covert == this.covert &&
          other.synced == this.synced);
}

class IncidentsCompanion extends UpdateCompanion<IncidentRow> {
  final Value<String> id;
  final Value<String> source;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<String> shareToken;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String?> address;
  final Value<int?> batteryLevel;
  final Value<bool> smsDispatched;
  final Value<bool> cloudDispatched;
  final Value<String?> audioPath;
  final Value<DateTime?> resolvedAt;
  final Value<bool> covert;
  final Value<bool> synced;
  final Value<int> rowid;
  const IncidentsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.shareToken = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.address = const Value.absent(),
    this.batteryLevel = const Value.absent(),
    this.smsDispatched = const Value.absent(),
    this.cloudDispatched = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.covert = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncidentsCompanion.insert({
    required String id,
    required String source,
    required String status,
    required DateTime createdAt,
    required String shareToken,
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.address = const Value.absent(),
    this.batteryLevel = const Value.absent(),
    this.smsDispatched = const Value.absent(),
    this.cloudDispatched = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.covert = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source),
       status = Value(status),
       createdAt = Value(createdAt),
       shareToken = Value(shareToken);
  static Insertable<IncidentRow> custom({
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? shareToken,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? address,
    Expression<int>? batteryLevel,
    Expression<bool>? smsDispatched,
    Expression<bool>? cloudDispatched,
    Expression<String>? audioPath,
    Expression<DateTime>? resolvedAt,
    Expression<bool>? covert,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (shareToken != null) 'share_token': shareToken,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (address != null) 'address': address,
      if (batteryLevel != null) 'battery_level': batteryLevel,
      if (smsDispatched != null) 'sms_dispatched': smsDispatched,
      if (cloudDispatched != null) 'cloud_dispatched': cloudDispatched,
      if (audioPath != null) 'audio_path': audioPath,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (covert != null) 'covert': covert,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncidentsCompanion copyWith({
    Value<String>? id,
    Value<String>? source,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<String>? shareToken,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<String?>? address,
    Value<int?>? batteryLevel,
    Value<bool>? smsDispatched,
    Value<bool>? cloudDispatched,
    Value<String?>? audioPath,
    Value<DateTime?>? resolvedAt,
    Value<bool>? covert,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return IncidentsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      shareToken: shareToken ?? this.shareToken,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      smsDispatched: smsDispatched ?? this.smsDispatched,
      cloudDispatched: cloudDispatched ?? this.cloudDispatched,
      audioPath: audioPath ?? this.audioPath,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      covert: covert ?? this.covert,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (shareToken.present) {
      map['share_token'] = Variable<String>(shareToken.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (batteryLevel.present) {
      map['battery_level'] = Variable<int>(batteryLevel.value);
    }
    if (smsDispatched.present) {
      map['sms_dispatched'] = Variable<bool>(smsDispatched.value);
    }
    if (cloudDispatched.present) {
      map['cloud_dispatched'] = Variable<bool>(cloudDispatched.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (covert.present) {
      map['covert'] = Variable<bool>(covert.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncidentsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('shareToken: $shareToken, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('address: $address, ')
          ..write('batteryLevel: $batteryLevel, ')
          ..write('smsDispatched: $smsDispatched, ')
          ..write('cloudDispatched: $cloudDispatched, ')
          ..write('audioPath: $audioPath, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('covert: $covert, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BreadcrumbsTable extends Breadcrumbs
    with TableInfo<$BreadcrumbsTable, BreadcrumbRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BreadcrumbsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _incidentIdMeta = const VerificationMeta(
    'incidentId',
  );
  @override
  late final GeneratedColumn<String> incidentId = GeneratedColumn<String>(
    'incident_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batteryMeta = const VerificationMeta(
    'battery',
  );
  @override
  late final GeneratedColumn<int> battery = GeneratedColumn<int>(
    'battery',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    incidentId,
    lat,
    lng,
    speed,
    accuracy,
    battery,
    recordedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'breadcrumbs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BreadcrumbRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('incident_id')) {
      context.handle(
        _incidentIdMeta,
        incidentId.isAcceptableOrUnknown(data['incident_id']!, _incidentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_incidentIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('battery')) {
      context.handle(
        _batteryMeta,
        battery.isAcceptableOrUnknown(data['battery']!, _batteryMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreadcrumbRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreadcrumbRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      incidentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}incident_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      battery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $BreadcrumbsTable createAlias(String alias) {
    return $BreadcrumbsTable(attachedDatabase, alias);
  }
}

class BreadcrumbRow extends DataClass implements Insertable<BreadcrumbRow> {
  final int id;
  final String incidentId;
  final double lat;
  final double lng;
  final double? speed;
  final double? accuracy;
  final int? battery;
  final DateTime recordedAt;
  final bool synced;
  const BreadcrumbRow({
    required this.id,
    required this.incidentId,
    required this.lat,
    required this.lng,
    this.speed,
    this.accuracy,
    this.battery,
    required this.recordedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['incident_id'] = Variable<String>(incidentId);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    if (!nullToAbsent || battery != null) {
      map['battery'] = Variable<int>(battery);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  BreadcrumbsCompanion toCompanion(bool nullToAbsent) {
    return BreadcrumbsCompanion(
      id: Value(id),
      incidentId: Value(incidentId),
      lat: Value(lat),
      lng: Value(lng),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      battery: battery == null && nullToAbsent
          ? const Value.absent()
          : Value(battery),
      recordedAt: Value(recordedAt),
      synced: Value(synced),
    );
  }

  factory BreadcrumbRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreadcrumbRow(
      id: serializer.fromJson<int>(json['id']),
      incidentId: serializer.fromJson<String>(json['incidentId']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      speed: serializer.fromJson<double?>(json['speed']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      battery: serializer.fromJson<int?>(json['battery']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'incidentId': serializer.toJson<String>(incidentId),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'speed': serializer.toJson<double?>(speed),
      'accuracy': serializer.toJson<double?>(accuracy),
      'battery': serializer.toJson<int?>(battery),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  BreadcrumbRow copyWith({
    int? id,
    String? incidentId,
    double? lat,
    double? lng,
    Value<double?> speed = const Value.absent(),
    Value<double?> accuracy = const Value.absent(),
    Value<int?> battery = const Value.absent(),
    DateTime? recordedAt,
    bool? synced,
  }) => BreadcrumbRow(
    id: id ?? this.id,
    incidentId: incidentId ?? this.incidentId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    speed: speed.present ? speed.value : this.speed,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    battery: battery.present ? battery.value : this.battery,
    recordedAt: recordedAt ?? this.recordedAt,
    synced: synced ?? this.synced,
  );
  BreadcrumbRow copyWithCompanion(BreadcrumbsCompanion data) {
    return BreadcrumbRow(
      id: data.id.present ? data.id.value : this.id,
      incidentId: data.incidentId.present
          ? data.incidentId.value
          : this.incidentId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      speed: data.speed.present ? data.speed.value : this.speed,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      battery: data.battery.present ? data.battery.value : this.battery,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreadcrumbRow(')
          ..write('id: $id, ')
          ..write('incidentId: $incidentId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speed: $speed, ')
          ..write('accuracy: $accuracy, ')
          ..write('battery: $battery, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    incidentId,
    lat,
    lng,
    speed,
    accuracy,
    battery,
    recordedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreadcrumbRow &&
          other.id == this.id &&
          other.incidentId == this.incidentId &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.speed == this.speed &&
          other.accuracy == this.accuracy &&
          other.battery == this.battery &&
          other.recordedAt == this.recordedAt &&
          other.synced == this.synced);
}

class BreadcrumbsCompanion extends UpdateCompanion<BreadcrumbRow> {
  final Value<int> id;
  final Value<String> incidentId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double?> speed;
  final Value<double?> accuracy;
  final Value<int?> battery;
  final Value<DateTime> recordedAt;
  final Value<bool> synced;
  const BreadcrumbsCompanion({
    this.id = const Value.absent(),
    this.incidentId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.speed = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.battery = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  BreadcrumbsCompanion.insert({
    this.id = const Value.absent(),
    required String incidentId,
    required double lat,
    required double lng,
    this.speed = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.battery = const Value.absent(),
    required DateTime recordedAt,
    this.synced = const Value.absent(),
  }) : incidentId = Value(incidentId),
       lat = Value(lat),
       lng = Value(lng),
       recordedAt = Value(recordedAt);
  static Insertable<BreadcrumbRow> custom({
    Expression<int>? id,
    Expression<String>? incidentId,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? speed,
    Expression<double>? accuracy,
    Expression<int>? battery,
    Expression<DateTime>? recordedAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (incidentId != null) 'incident_id': incidentId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (speed != null) 'speed': speed,
      if (accuracy != null) 'accuracy': accuracy,
      if (battery != null) 'battery': battery,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (synced != null) 'synced': synced,
    });
  }

  BreadcrumbsCompanion copyWith({
    Value<int>? id,
    Value<String>? incidentId,
    Value<double>? lat,
    Value<double>? lng,
    Value<double?>? speed,
    Value<double?>? accuracy,
    Value<int?>? battery,
    Value<DateTime>? recordedAt,
    Value<bool>? synced,
  }) {
    return BreadcrumbsCompanion(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      battery: battery ?? this.battery,
      recordedAt: recordedAt ?? this.recordedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (incidentId.present) {
      map['incident_id'] = Variable<String>(incidentId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (battery.present) {
      map['battery'] = Variable<int>(battery.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BreadcrumbsCompanion(')
          ..write('id: $id, ')
          ..write('incidentId: $incidentId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speed: $speed, ')
          ..write('accuracy: $accuracy, ')
          ..write('battery: $battery, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $HavensCacheTable extends HavensCache
    with TableInfo<$HavensCacheTable, HavenCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HavensCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _open24hMeta = const VerificationMeta(
    'open24h',
  );
  @override
  late final GeneratedColumn<bool> open24h = GeneratedColumn<bool>(
    'open24h',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("open24h" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    lat,
    lng,
    phone,
    address,
    open24h,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'havens_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<HavenCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('open24h')) {
      context.handle(
        _open24hMeta,
        open24h.isAcceptableOrUnknown(data['open24h']!, _open24hMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HavenCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HavenCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      open24h: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}open24h'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $HavensCacheTable createAlias(String alias) {
    return $HavensCacheTable(attachedDatabase, alias);
  }
}

class HavenCacheRow extends DataClass implements Insertable<HavenCacheRow> {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final String? phone;
  final String? address;
  final bool open24h;
  final DateTime cachedAt;
  const HavenCacheRow({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.phone,
    this.address,
    required this.open24h,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['open24h'] = Variable<bool>(open24h);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  HavensCacheCompanion toCompanion(bool nullToAbsent) {
    return HavensCacheCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      lat: Value(lat),
      lng: Value(lng),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      open24h: Value(open24h),
      cachedAt: Value(cachedAt),
    );
  }

  factory HavenCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HavenCacheRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      open24h: serializer.fromJson<bool>(json['open24h']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'open24h': serializer.toJson<bool>(open24h),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  HavenCacheRow copyWith({
    String? id,
    String? name,
    String? category,
    double? lat,
    double? lng,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    bool? open24h,
    DateTime? cachedAt,
  }) => HavenCacheRow(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    open24h: open24h ?? this.open24h,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  HavenCacheRow copyWithCompanion(HavensCacheCompanion data) {
    return HavenCacheRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      open24h: data.open24h.present ? data.open24h.value : this.open24h,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HavenCacheRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('open24h: $open24h, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    lat,
    lng,
    phone,
    address,
    open24h,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HavenCacheRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.open24h == this.open24h &&
          other.cachedAt == this.cachedAt);
}

class HavensCacheCompanion extends UpdateCompanion<HavenCacheRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<bool> open24h;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const HavensCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.open24h = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HavensCacheCompanion.insert({
    required String id,
    required String name,
    required String category,
    required double lat,
    required double lng,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.open24h = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       lat = Value(lat),
       lng = Value(lng),
       cachedAt = Value(cachedAt);
  static Insertable<HavenCacheRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<bool>? open24h,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (open24h != null) 'open24h': open24h,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HavensCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<double>? lat,
    Value<double>? lng,
    Value<String?>? phone,
    Value<String?>? address,
    Value<bool>? open24h,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return HavensCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      open24h: open24h ?? this.open24h,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (open24h.present) {
      map['open24h'] = Variable<bool>(open24h.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HavensCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('open24h: $open24h, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SafePlacesTable extends SafePlaces
    with TableInfo<$SafePlacesTable, SafePlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SafePlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<double> radiusM = GeneratedColumn<double>(
    'radius_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(150),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, lat, lng, radiusM];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'safe_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<SafePlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SafePlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SafePlaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_m'],
      )!,
    );
  }

  @override
  $SafePlacesTable createAlias(String alias) {
    return $SafePlacesTable(attachedDatabase, alias);
  }
}

class SafePlaceRow extends DataClass implements Insertable<SafePlaceRow> {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusM;
  const SafePlaceRow({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['radius_m'] = Variable<double>(radiusM);
    return map;
  }

  SafePlacesCompanion toCompanion(bool nullToAbsent) {
    return SafePlacesCompanion(
      id: Value(id),
      name: Value(name),
      lat: Value(lat),
      lng: Value(lng),
      radiusM: Value(radiusM),
    );
  }

  factory SafePlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SafePlaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      radiusM: serializer.fromJson<double>(json['radiusM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'radiusM': serializer.toJson<double>(radiusM),
    };
  }

  SafePlaceRow copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    double? radiusM,
  }) => SafePlaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    radiusM: radiusM ?? this.radiusM,
  );
  SafePlaceRow copyWithCompanion(SafePlacesCompanion data) {
    return SafePlaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SafePlaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('radiusM: $radiusM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, lat, lng, radiusM);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SafePlaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.radiusM == this.radiusM);
}

class SafePlacesCompanion extends UpdateCompanion<SafePlaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> radiusM;
  final Value<int> rowid;
  const SafePlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SafePlacesCompanion.insert({
    required String id,
    required String name,
    required double lat,
    required double lng,
    this.radiusM = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<SafePlaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? radiusM,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusM != null) 'radius_m': radiusM,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SafePlacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? radiusM,
    Value<int>? rowid,
  }) {
    return SafePlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusM: radiusM ?? this.radiusM,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<double>(radiusM.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SafePlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('radiusM: $radiusM, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, role, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  const ChatMessageRow({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessageRow copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
  }) => ChatMessageRow(
    id: id ?? this.id,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String role,
    required String content,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? role,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityKeyMeta = const VerificationMeta(
    'entityKey',
  );
  @override
  late final GeneratedColumn<String> entityKey = GeneratedColumn<String>(
    'entity_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    payload,
    entityKey,
    attempts,
    nextAttemptAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('entity_key')) {
      context.handle(
        _entityKeyMeta,
        entityKey.isAcceptableOrUnknown(data['entity_key']!, _entityKeyMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      entityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_key'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final int id;

  /// `incident` or `breadcrumb`.
  final String entity;

  /// Remote row as JSON.
  final String payload;

  /// For incidents: the incident id, so a newer enqueue replaces the old one.
  final String? entityKey;
  final int attempts;
  final DateTime nextAttemptAt;
  final DateTime createdAt;
  const SyncQueueRow({
    required this.id,
    required this.entity,
    required this.payload,
    this.entityKey,
    required this.attempts,
    required this.nextAttemptAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity'] = Variable<String>(entity);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || entityKey != null) {
      map['entity_key'] = Variable<String>(entityKey);
    }
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entity: Value(entity),
      payload: Value(payload),
      entityKey: entityKey == null && nullToAbsent
          ? const Value.absent()
          : Value(entityKey),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<int>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      payload: serializer.fromJson<String>(json['payload']),
      entityKey: serializer.fromJson<String?>(json['entityKey']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entity': serializer.toJson<String>(entity),
      'payload': serializer.toJson<String>(payload),
      'entityKey': serializer.toJson<String?>(entityKey),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueRow copyWith({
    int? id,
    String? entity,
    String? payload,
    Value<String?> entityKey = const Value.absent(),
    int? attempts,
    DateTime? nextAttemptAt,
    DateTime? createdAt,
  }) => SyncQueueRow(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    payload: payload ?? this.payload,
    entityKey: entityKey.present ? entityKey.value : this.entityKey,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      payload: data.payload.present ? data.payload.value : this.payload,
      entityKey: data.entityKey.present ? data.entityKey.value : this.entityKey,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('payload: $payload, ')
          ..write('entityKey: $entityKey, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entity,
    payload,
    entityKey,
    attempts,
    nextAttemptAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.payload == this.payload &&
          other.entityKey == this.entityKey &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<int> id;
  final Value<String> entity;
  final Value<String> payload;
  final Value<String?> entityKey;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.payload = const Value.absent(),
    this.entityKey = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entity,
    required String payload,
    this.entityKey = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAt,
    required DateTime createdAt,
  }) : entity = Value(entity),
       payload = Value(payload),
       nextAttemptAt = Value(nextAttemptAt),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<int>? id,
    Expression<String>? entity,
    Expression<String>? payload,
    Expression<String>? entityKey,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (payload != null) 'payload': payload,
      if (entityKey != null) 'entity_key': entityKey,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entity,
    Value<String>? payload,
    Value<String?>? entityKey,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      payload: payload ?? this.payload,
      entityKey: entityKey ?? this.entityKey,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (entityKey.present) {
      map['entity_key'] = Variable<String>(entityKey.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('payload: $payload, ')
          ..write('entityKey: $entityKey, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KvTable extends Kv with TableInfo<$KvTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KvTable createAlias(String alias) {
    return $KvTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvCompanion toCompanion(bool nullToAbsent) {
    return KvCompanion(key: Value(key), value: Value(value));
  }

  factory KvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) =>
      KvRow(key: key ?? this.key, value: value ?? this.value);
  KvRow copyWithCompanion(KvCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class KvCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $IncidentsTable incidents = $IncidentsTable(this);
  late final $BreadcrumbsTable breadcrumbs = $BreadcrumbsTable(this);
  late final $HavensCacheTable havensCache = $HavensCacheTable(this);
  late final $SafePlacesTable safePlaces = $SafePlacesTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $KvTable kv = $KvTable(this);
  late final Index idxIncidentsCreatedAt = Index(
    'idx_incidents_created_at',
    'CREATE INDEX idx_incidents_created_at ON incidents (created_at)',
  );
  late final Index idxBreadcrumbsIncidentId = Index(
    'idx_breadcrumbs_incident_id',
    'CREATE INDEX idx_breadcrumbs_incident_id ON breadcrumbs (incident_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contacts,
    incidents,
    breadcrumbs,
    havensCache,
    safePlaces,
    chatMessages,
    syncQueue,
    kv,
    idxIncidentsCreatedAt,
    idxBreadcrumbsIncidentId,
  ];
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  required String id,
  required String name,
  required String phone,
  Value<String> relationship,
  Value<int> priority,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<String> relationship,
  Value<int> priority,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          ContactRow,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (
            ContactRow,
            BaseReferences<_$AppDatabase, $ContactsTable, ContactRow>,
          ),
          ContactRow,
          PrefetchHooks Function()
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                name: name,
                phone: phone,
                relationship: relationship,
                priority: priority,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String phone,
                Value<String> relationship = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                relationship: relationship,
                priority: priority,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactsTable, ContactRow>(table),
                  BaseReferences<_$AppDatabase, $ContactsTable, ContactRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      ContactRow,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (ContactRow, BaseReferences<_$AppDatabase, $ContactsTable, ContactRow>),
      ContactRow,
      PrefetchHooks Function()
    >;
typedef $$IncidentsTableCreateCompanionBuilder = IncidentsCompanion Function({
  required String id,
  required String source,
  required String status,
  required DateTime createdAt,
  required String shareToken,
  Value<double?> lat,
  Value<double?> lng,
  Value<String?> address,
  Value<int?> batteryLevel,
  Value<bool> smsDispatched,
  Value<bool> cloudDispatched,
  Value<String?> audioPath,
  Value<DateTime?> resolvedAt,
  Value<bool> covert,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$IncidentsTableUpdateCompanionBuilder = IncidentsCompanion Function({
  Value<String> id,
  Value<String> source,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<String> shareToken,
  Value<double?> lat,
  Value<double?> lng,
  Value<String?> address,
  Value<int?> batteryLevel,
  Value<bool> smsDispatched,
  Value<bool> cloudDispatched,
  Value<String?> audioPath,
  Value<DateTime?> resolvedAt,
  Value<bool> covert,
  Value<bool> synced,
  Value<int> rowid,
});

class $$IncidentsTableFilterComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareToken => $composableBuilder(
    column: $table.shareToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryLevel => $composableBuilder(
    column: $table.batteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get smsDispatched => $composableBuilder(
    column: $table.smsDispatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cloudDispatched => $composableBuilder(
    column: $table.cloudDispatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get covert => $composableBuilder(
    column: $table.covert,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IncidentsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareToken => $composableBuilder(
    column: $table.shareToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryLevel => $composableBuilder(
    column: $table.batteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get smsDispatched => $composableBuilder(
    column: $table.smsDispatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cloudDispatched => $composableBuilder(
    column: $table.cloudDispatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get covert => $composableBuilder(
    column: $table.covert,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncidentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get shareToken => $composableBuilder(
    column: $table.shareToken,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get batteryLevel => $composableBuilder(
    column: $table.batteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get smsDispatched => $composableBuilder(
    column: $table.smsDispatched,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cloudDispatched => $composableBuilder(
    column: $table.cloudDispatched,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get covert =>
      $composableBuilder(column: $table.covert, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$IncidentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncidentsTable,
          IncidentRow,
          $$IncidentsTableFilterComposer,
          $$IncidentsTableOrderingComposer,
          $$IncidentsTableAnnotationComposer,
          $$IncidentsTableCreateCompanionBuilder,
          $$IncidentsTableUpdateCompanionBuilder,
          (
            IncidentRow,
            BaseReferences<_$AppDatabase, $IncidentsTable, IncidentRow>,
          ),
          IncidentRow,
          PrefetchHooks Function()
        > {
  $$IncidentsTableTableManager(_$AppDatabase db, $IncidentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncidentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncidentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncidentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> shareToken = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<int?> batteryLevel = const Value.absent(),
                Value<bool> smsDispatched = const Value.absent(),
                Value<bool> cloudDispatched = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<bool> covert = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncidentsCompanion(
                id: id,
                source: source,
                status: status,
                createdAt: createdAt,
                shareToken: shareToken,
                lat: lat,
                lng: lng,
                address: address,
                batteryLevel: batteryLevel,
                smsDispatched: smsDispatched,
                cloudDispatched: cloudDispatched,
                audioPath: audioPath,
                resolvedAt: resolvedAt,
                covert: covert,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String source,
                required String status,
                required DateTime createdAt,
                required String shareToken,
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<int?> batteryLevel = const Value.absent(),
                Value<bool> smsDispatched = const Value.absent(),
                Value<bool> cloudDispatched = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<bool> covert = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncidentsCompanion.insert(
                id: id,
                source: source,
                status: status,
                createdAt: createdAt,
                shareToken: shareToken,
                lat: lat,
                lng: lng,
                address: address,
                batteryLevel: batteryLevel,
                smsDispatched: smsDispatched,
                cloudDispatched: cloudDispatched,
                audioPath: audioPath,
                resolvedAt: resolvedAt,
                covert: covert,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncidentsTable, IncidentRow>(table),
                  BaseReferences<_$AppDatabase, $IncidentsTable, IncidentRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IncidentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncidentsTable,
      IncidentRow,
      $$IncidentsTableFilterComposer,
      $$IncidentsTableOrderingComposer,
      $$IncidentsTableAnnotationComposer,
      $$IncidentsTableCreateCompanionBuilder,
      $$IncidentsTableUpdateCompanionBuilder,
      (
        IncidentRow,
        BaseReferences<_$AppDatabase, $IncidentsTable, IncidentRow>,
      ),
      IncidentRow,
      PrefetchHooks Function()
    >;
typedef $$BreadcrumbsTableCreateCompanionBuilder =
    BreadcrumbsCompanion Function({
      Value<int> id,
      required String incidentId,
      required double lat,
      required double lng,
      Value<double?> speed,
      Value<double?> accuracy,
      Value<int?> battery,
      required DateTime recordedAt,
      Value<bool> synced,
    });
typedef $$BreadcrumbsTableUpdateCompanionBuilder =
    BreadcrumbsCompanion Function({
      Value<int> id,
      Value<String> incidentId,
      Value<double> lat,
      Value<double> lng,
      Value<double?> speed,
      Value<double?> accuracy,
      Value<int?> battery,
      Value<DateTime> recordedAt,
      Value<bool> synced,
    });

class $$BreadcrumbsTableFilterComposer
    extends Composer<_$AppDatabase, $BreadcrumbsTable> {
  $$BreadcrumbsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incidentId => $composableBuilder(
    column: $table.incidentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get battery => $composableBuilder(
    column: $table.battery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BreadcrumbsTableOrderingComposer
    extends Composer<_$AppDatabase, $BreadcrumbsTable> {
  $$BreadcrumbsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incidentId => $composableBuilder(
    column: $table.incidentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get battery => $composableBuilder(
    column: $table.battery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BreadcrumbsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BreadcrumbsTable> {
  $$BreadcrumbsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get incidentId => $composableBuilder(
    column: $table.incidentId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get battery =>
      $composableBuilder(column: $table.battery, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$BreadcrumbsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BreadcrumbsTable,
          BreadcrumbRow,
          $$BreadcrumbsTableFilterComposer,
          $$BreadcrumbsTableOrderingComposer,
          $$BreadcrumbsTableAnnotationComposer,
          $$BreadcrumbsTableCreateCompanionBuilder,
          $$BreadcrumbsTableUpdateCompanionBuilder,
          (
            BreadcrumbRow,
            BaseReferences<_$AppDatabase, $BreadcrumbsTable, BreadcrumbRow>,
          ),
          BreadcrumbRow,
          PrefetchHooks Function()
        > {
  $$BreadcrumbsTableTableManager(_$AppDatabase db, $BreadcrumbsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BreadcrumbsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BreadcrumbsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BreadcrumbsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> incidentId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<int?> battery = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => BreadcrumbsCompanion(
                id: id,
                incidentId: incidentId,
                lat: lat,
                lng: lng,
                speed: speed,
                accuracy: accuracy,
                battery: battery,
                recordedAt: recordedAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String incidentId,
                required double lat,
                required double lng,
                Value<double?> speed = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<int?> battery = const Value.absent(),
                required DateTime recordedAt,
                Value<bool> synced = const Value.absent(),
              }) => BreadcrumbsCompanion.insert(
                id: id,
                incidentId: incidentId,
                lat: lat,
                lng: lng,
                speed: speed,
                accuracy: accuracy,
                battery: battery,
                recordedAt: recordedAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BreadcrumbsTable, BreadcrumbRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BreadcrumbsTable,
                    BreadcrumbRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BreadcrumbsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BreadcrumbsTable,
      BreadcrumbRow,
      $$BreadcrumbsTableFilterComposer,
      $$BreadcrumbsTableOrderingComposer,
      $$BreadcrumbsTableAnnotationComposer,
      $$BreadcrumbsTableCreateCompanionBuilder,
      $$BreadcrumbsTableUpdateCompanionBuilder,
      (
        BreadcrumbRow,
        BaseReferences<_$AppDatabase, $BreadcrumbsTable, BreadcrumbRow>,
      ),
      BreadcrumbRow,
      PrefetchHooks Function()
    >;
typedef $$HavensCacheTableCreateCompanionBuilder =
    HavensCacheCompanion Function({
      required String id,
      required String name,
      required String category,
      required double lat,
      required double lng,
      Value<String?> phone,
      Value<String?> address,
      Value<bool> open24h,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$HavensCacheTableUpdateCompanionBuilder =
    HavensCacheCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<double> lat,
      Value<double> lng,
      Value<String?> phone,
      Value<String?> address,
      Value<bool> open24h,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$HavensCacheTableFilterComposer
    extends Composer<_$AppDatabase, $HavensCacheTable> {
  $$HavensCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get open24h => $composableBuilder(
    column: $table.open24h,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HavensCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $HavensCacheTable> {
  $$HavensCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get open24h => $composableBuilder(
    column: $table.open24h,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HavensCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $HavensCacheTable> {
  $$HavensCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get open24h =>
      $composableBuilder(column: $table.open24h, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$HavensCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HavensCacheTable,
          HavenCacheRow,
          $$HavensCacheTableFilterComposer,
          $$HavensCacheTableOrderingComposer,
          $$HavensCacheTableAnnotationComposer,
          $$HavensCacheTableCreateCompanionBuilder,
          $$HavensCacheTableUpdateCompanionBuilder,
          (
            HavenCacheRow,
            BaseReferences<_$AppDatabase, $HavensCacheTable, HavenCacheRow>,
          ),
          HavenCacheRow,
          PrefetchHooks Function()
        > {
  $$HavensCacheTableTableManager(_$AppDatabase db, $HavensCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HavensCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HavensCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HavensCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<bool> open24h = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HavensCacheCompanion(
                id: id,
                name: name,
                category: category,
                lat: lat,
                lng: lng,
                phone: phone,
                address: address,
                open24h: open24h,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required double lat,
                required double lng,
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<bool> open24h = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => HavensCacheCompanion.insert(
                id: id,
                name: name,
                category: category,
                lat: lat,
                lng: lng,
                phone: phone,
                address: address,
                open24h: open24h,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HavensCacheTable, HavenCacheRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HavensCacheTable,
                    HavenCacheRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HavensCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HavensCacheTable,
      HavenCacheRow,
      $$HavensCacheTableFilterComposer,
      $$HavensCacheTableOrderingComposer,
      $$HavensCacheTableAnnotationComposer,
      $$HavensCacheTableCreateCompanionBuilder,
      $$HavensCacheTableUpdateCompanionBuilder,
      (
        HavenCacheRow,
        BaseReferences<_$AppDatabase, $HavensCacheTable, HavenCacheRow>,
      ),
      HavenCacheRow,
      PrefetchHooks Function()
    >;
typedef $$SafePlacesTableCreateCompanionBuilder = SafePlacesCompanion Function({
  required String id,
  required String name,
  required double lat,
  required double lng,
  Value<double> radiusM,
  Value<int> rowid,
});
typedef $$SafePlacesTableUpdateCompanionBuilder = SafePlacesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<double> lat,
  Value<double> lng,
  Value<double> radiusM,
  Value<int> rowid,
});

class $$SafePlacesTableFilterComposer
    extends Composer<_$AppDatabase, $SafePlacesTable> {
  $$SafePlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SafePlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $SafePlacesTable> {
  $$SafePlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SafePlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SafePlacesTable> {
  $$SafePlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);
}

class $$SafePlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SafePlacesTable,
          SafePlaceRow,
          $$SafePlacesTableFilterComposer,
          $$SafePlacesTableOrderingComposer,
          $$SafePlacesTableAnnotationComposer,
          $$SafePlacesTableCreateCompanionBuilder,
          $$SafePlacesTableUpdateCompanionBuilder,
          (
            SafePlaceRow,
            BaseReferences<_$AppDatabase, $SafePlacesTable, SafePlaceRow>,
          ),
          SafePlaceRow,
          PrefetchHooks Function()
        > {
  $$SafePlacesTableTableManager(_$AppDatabase db, $SafePlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SafePlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SafePlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SafePlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> radiusM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SafePlacesCompanion(
                id: id,
                name: name,
                lat: lat,
                lng: lng,
                radiusM: radiusM,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double lat,
                required double lng,
                Value<double> radiusM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SafePlacesCompanion.insert(
                id: id,
                name: name,
                lat: lat,
                lng: lng,
                radiusM: radiusM,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SafePlacesTable, SafePlaceRow>(table),
                  BaseReferences<_$AppDatabase, $SafePlacesTable, SafePlaceRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SafePlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SafePlacesTable,
      SafePlaceRow,
      $$SafePlacesTableFilterComposer,
      $$SafePlacesTableOrderingComposer,
      $$SafePlacesTableAnnotationComposer,
      $$SafePlacesTableCreateCompanionBuilder,
      $$SafePlacesTableUpdateCompanionBuilder,
      (
        SafePlaceRow,
        BaseReferences<_$AppDatabase, $SafePlacesTable, SafePlaceRow>,
      ),
      SafePlaceRow,
      PrefetchHooks Function()
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required String role,
      required String content,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<String> role,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessageRow,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (
            ChatMessageRow,
            BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow>,
          ),
          ChatMessageRow,
          PrefetchHooks Function()
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                role: role,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String role,
                required String content,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                role: role,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChatMessagesTable, ChatMessageRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ChatMessagesTable,
                    ChatMessageRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessageRow,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (
        ChatMessageRow,
        BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow>,
      ),
      ChatMessageRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String entity,
  required String payload,
  Value<String?> entityKey,
  Value<int> attempts,
  required DateTime nextAttemptAt,
  required DateTime createdAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> entity,
  Value<String> payload,
  Value<String?> entityKey,
  Value<int> attempts,
  Value<DateTime> nextAttemptAt,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get entityKey =>
      $composableBuilder(column: $table.entityKey, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueRow,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueRow,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
          ),
          SyncQueueRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> entityKey = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entity: entity,
                payload: payload,
                entityKey: entityKey,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entity,
                required String payload,
                Value<String?> entityKey = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime nextAttemptAt,
                required DateTime createdAt,
              }) => SyncQueueCompanion.insert(
                id: id,
                entity: entity,
                payload: payload,
                entityKey: entityKey,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueRow>(table),
                  BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueRow,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueRow,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
      ),
      SyncQueueRow,
      PrefetchHooks Function()
    >;
typedef $$KvTableCreateCompanionBuilder = KvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KvTableUpdateCompanionBuilder = KvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KvTableFilterComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvTableOrderingComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvTableAnnotationComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvTable,
          KvRow,
          $$KvTableFilterComposer,
          $$KvTableOrderingComposer,
          $$KvTableAnnotationComposer,
          $$KvTableCreateCompanionBuilder,
          $$KvTableUpdateCompanionBuilder,
          (KvRow, BaseReferences<_$AppDatabase, $KvTable, KvRow>),
          KvRow,
          PrefetchHooks Function()
        > {
  $$KvTableTableManager(_$AppDatabase db, $KvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KvCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KvTable, KvRow>(table),
                  BaseReferences<_$AppDatabase, $KvTable, KvRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvTable,
      KvRow,
      $$KvTableFilterComposer,
      $$KvTableOrderingComposer,
      $$KvTableAnnotationComposer,
      $$KvTableCreateCompanionBuilder,
      $$KvTableUpdateCompanionBuilder,
      (KvRow, BaseReferences<_$AppDatabase, $KvTable, KvRow>),
      KvRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$IncidentsTableTableManager get incidents =>
      $$IncidentsTableTableManager(_db, _db.incidents);
  $$BreadcrumbsTableTableManager get breadcrumbs =>
      $$BreadcrumbsTableTableManager(_db, _db.breadcrumbs);
  $$HavensCacheTableTableManager get havensCache =>
      $$HavensCacheTableTableManager(_db, _db.havensCache);
  $$SafePlacesTableTableManager get safePlaces =>
      $$SafePlacesTableTableManager(_db, _db.safePlaces);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$KvTableTableManager get kv => $$KvTableTableManager(_db, _db.kv);
}
