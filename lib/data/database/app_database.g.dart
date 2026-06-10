// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BoatsTable extends Boats with TableInfo<$BoatsTable, Boat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sailNumberMeta = const VerificationMeta(
    'sailNumber',
  );
  @override
  late final GeneratedColumn<String> sailNumber = GeneratedColumn<String>(
    'sail_number',
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
  static const VerificationMeta _boatClassMeta = const VerificationMeta(
    'boatClass',
  );
  @override
  late final GeneratedColumn<String> boatClass = GeneratedColumn<String>(
    'boat_class',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxSpeedMeta = const VerificationMeta(
    'maxSpeed',
  );
  @override
  late final GeneratedColumn<double> maxSpeed = GeneratedColumn<double>(
    'max_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sailNumber,
    name,
    boatClass,
    maxSpeed,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Boat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sail_number')) {
      context.handle(
        _sailNumberMeta,
        sailNumber.isAcceptableOrUnknown(data['sail_number']!, _sailNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_sailNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('boat_class')) {
      context.handle(
        _boatClassMeta,
        boatClass.isAcceptableOrUnknown(data['boat_class']!, _boatClassMeta),
      );
    } else if (isInserting) {
      context.missing(_boatClassMeta);
    }
    if (data.containsKey('max_speed')) {
      context.handle(
        _maxSpeedMeta,
        maxSpeed.isAcceptableOrUnknown(data['max_speed']!, _maxSpeedMeta),
      );
    } else if (isInserting) {
      context.missing(_maxSpeedMeta);
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
  Boat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Boat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sailNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sail_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      boatClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_class'],
      )!,
      maxSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_speed'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $BoatsTable createAlias(String alias) {
    return $BoatsTable(attachedDatabase, alias);
  }
}

class Boat extends DataClass implements Insertable<Boat> {
  final String id;
  final String sailNumber;
  final String name;
  final String boatClass;
  final double maxSpeed;
  final bool isActive;
  const Boat({
    required this.id,
    required this.sailNumber,
    required this.name,
    required this.boatClass,
    required this.maxSpeed,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sail_number'] = Variable<String>(sailNumber);
    map['name'] = Variable<String>(name);
    map['boat_class'] = Variable<String>(boatClass);
    map['max_speed'] = Variable<double>(maxSpeed);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  BoatsCompanion toCompanion(bool nullToAbsent) {
    return BoatsCompanion(
      id: Value(id),
      sailNumber: Value(sailNumber),
      name: Value(name),
      boatClass: Value(boatClass),
      maxSpeed: Value(maxSpeed),
      isActive: Value(isActive),
    );
  }

  factory Boat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Boat(
      id: serializer.fromJson<String>(json['id']),
      sailNumber: serializer.fromJson<String>(json['sailNumber']),
      name: serializer.fromJson<String>(json['name']),
      boatClass: serializer.fromJson<String>(json['boatClass']),
      maxSpeed: serializer.fromJson<double>(json['maxSpeed']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sailNumber': serializer.toJson<String>(sailNumber),
      'name': serializer.toJson<String>(name),
      'boatClass': serializer.toJson<String>(boatClass),
      'maxSpeed': serializer.toJson<double>(maxSpeed),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Boat copyWith({
    String? id,
    String? sailNumber,
    String? name,
    String? boatClass,
    double? maxSpeed,
    bool? isActive,
  }) => Boat(
    id: id ?? this.id,
    sailNumber: sailNumber ?? this.sailNumber,
    name: name ?? this.name,
    boatClass: boatClass ?? this.boatClass,
    maxSpeed: maxSpeed ?? this.maxSpeed,
    isActive: isActive ?? this.isActive,
  );
  Boat copyWithCompanion(BoatsCompanion data) {
    return Boat(
      id: data.id.present ? data.id.value : this.id,
      sailNumber: data.sailNumber.present
          ? data.sailNumber.value
          : this.sailNumber,
      name: data.name.present ? data.name.value : this.name,
      boatClass: data.boatClass.present ? data.boatClass.value : this.boatClass,
      maxSpeed: data.maxSpeed.present ? data.maxSpeed.value : this.maxSpeed,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Boat(')
          ..write('id: $id, ')
          ..write('sailNumber: $sailNumber, ')
          ..write('name: $name, ')
          ..write('boatClass: $boatClass, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sailNumber, name, boatClass, maxSpeed, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Boat &&
          other.id == this.id &&
          other.sailNumber == this.sailNumber &&
          other.name == this.name &&
          other.boatClass == this.boatClass &&
          other.maxSpeed == this.maxSpeed &&
          other.isActive == this.isActive);
}

class BoatsCompanion extends UpdateCompanion<Boat> {
  final Value<String> id;
  final Value<String> sailNumber;
  final Value<String> name;
  final Value<String> boatClass;
  final Value<double> maxSpeed;
  final Value<bool> isActive;
  final Value<int> rowid;
  const BoatsCompanion({
    this.id = const Value.absent(),
    this.sailNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.boatClass = const Value.absent(),
    this.maxSpeed = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoatsCompanion.insert({
    required String id,
    required String sailNumber,
    required String name,
    required String boatClass,
    required double maxSpeed,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sailNumber = Value(sailNumber),
       name = Value(name),
       boatClass = Value(boatClass),
       maxSpeed = Value(maxSpeed);
  static Insertable<Boat> custom({
    Expression<String>? id,
    Expression<String>? sailNumber,
    Expression<String>? name,
    Expression<String>? boatClass,
    Expression<double>? maxSpeed,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sailNumber != null) 'sail_number': sailNumber,
      if (name != null) 'name': name,
      if (boatClass != null) 'boat_class': boatClass,
      if (maxSpeed != null) 'max_speed': maxSpeed,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoatsCompanion copyWith({
    Value<String>? id,
    Value<String>? sailNumber,
    Value<String>? name,
    Value<String>? boatClass,
    Value<double>? maxSpeed,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return BoatsCompanion(
      id: id ?? this.id,
      sailNumber: sailNumber ?? this.sailNumber,
      name: name ?? this.name,
      boatClass: boatClass ?? this.boatClass,
      maxSpeed: maxSpeed ?? this.maxSpeed,
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
    if (sailNumber.present) {
      map['sail_number'] = Variable<String>(sailNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (boatClass.present) {
      map['boat_class'] = Variable<String>(boatClass.value);
    }
    if (maxSpeed.present) {
      map['max_speed'] = Variable<double>(maxSpeed.value);
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
    return (StringBuffer('BoatsCompanion(')
          ..write('id: $id, ')
          ..write('sailNumber: $sailNumber, ')
          ..write('name: $name, ')
          ..write('boatClass: $boatClass, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _boatIdMeta = const VerificationMeta('boatId');
  @override
  late final GeneratedColumn<String> boatId = GeneratedColumn<String>(
    'boat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boats (id)',
    ),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    boatId,
    startTime,
    endTime,
    isComplete,
    isSynced,
    distance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
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
    if (data.containsKey('boat_id')) {
      context.handle(
        _boatIdMeta,
        boatId.isAcceptableOrUnknown(data['boat_id']!, _boatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boatIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      boatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boat_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String name;
  final String boatId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isComplete;
  final bool isSynced;
  final double? distance;
  const Session({
    required this.id,
    required this.name,
    required this.boatId,
    required this.startTime,
    this.endTime,
    required this.isComplete,
    required this.isSynced,
    this.distance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['boat_id'] = Variable<String>(boatId);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['is_complete'] = Variable<bool>(isComplete);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      name: Value(name),
      boatId: Value(boatId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      isComplete: Value(isComplete),
      isSynced: Value(isSynced),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      boatId: serializer.fromJson<String>(json['boatId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      distance: serializer.fromJson<double?>(json['distance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'boatId': serializer.toJson<String>(boatId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'isComplete': serializer.toJson<bool>(isComplete),
      'isSynced': serializer.toJson<bool>(isSynced),
      'distance': serializer.toJson<double?>(distance),
    };
  }

  Session copyWith({
    String? id,
    String? name,
    String? boatId,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    bool? isComplete,
    bool? isSynced,
    Value<double?> distance = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    name: name ?? this.name,
    boatId: boatId ?? this.boatId,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    isComplete: isComplete ?? this.isComplete,
    isSynced: isSynced ?? this.isSynced,
    distance: distance.present ? distance.value : this.distance,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      boatId: data.boatId.present ? data.boatId.value : this.boatId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      distance: data.distance.present ? data.distance.value : this.distance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('boatId: $boatId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isComplete: $isComplete, ')
          ..write('isSynced: $isSynced, ')
          ..write('distance: $distance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    boatId,
    startTime,
    endTime,
    isComplete,
    isSynced,
    distance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.name == this.name &&
          other.boatId == this.boatId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isComplete == this.isComplete &&
          other.isSynced == this.isSynced &&
          other.distance == this.distance);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> boatId;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<bool> isComplete;
  final Value<bool> isSynced;
  final Value<double?> distance;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.boatId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.distance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String name,
    required String boatId,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.distance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       boatId = Value(boatId),
       startTime = Value(startTime);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? boatId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? isComplete,
    Expression<bool>? isSynced,
    Expression<double>? distance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (boatId != null) 'boat_id': boatId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isComplete != null) 'is_complete': isComplete,
      if (isSynced != null) 'is_synced': isSynced,
      if (distance != null) 'distance': distance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? boatId,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<bool>? isComplete,
    Value<bool>? isSynced,
    Value<double?>? distance,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      boatId: boatId ?? this.boatId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isComplete: isComplete ?? this.isComplete,
      isSynced: isSynced ?? this.isSynced,
      distance: distance ?? this.distance,
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
    if (boatId.present) {
      map['boat_id'] = Variable<String>(boatId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('boatId: $boatId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isComplete: $isComplete, ')
          ..write('isSynced: $isSynced, ')
          ..write('distance: $distance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GpsPointsTable extends GpsPoints
    with TableInfo<$GpsPointsTable, GpsPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GpsPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sogMeta = const VerificationMeta('sog');
  @override
  late final GeneratedColumn<double> sog = GeneratedColumn<double>(
    'sog',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cogMeta = const VerificationMeta('cog');
  @override
  late final GeneratedColumn<double> cog = GeneratedColumn<double>(
    'cog',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heelMeta = const VerificationMeta('heel');
  @override
  late final GeneratedColumn<double> heel = GeneratedColumn<double>(
    'heel',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pitchMeta = const VerificationMeta('pitch');
  @override
  late final GeneratedColumn<double> pitch = GeneratedColumn<double>(
    'pitch',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _magHeadingMeta = const VerificationMeta(
    'magHeading',
  );
  @override
  late final GeneratedColumn<double> magHeading = GeneratedColumn<double>(
    'mag_heading',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    timestamp,
    lat,
    lon,
    sog,
    cog,
    heel,
    pitch,
    magHeading,
    accuracy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gps_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<GpsPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('sog')) {
      context.handle(
        _sogMeta,
        sog.isAcceptableOrUnknown(data['sog']!, _sogMeta),
      );
    } else if (isInserting) {
      context.missing(_sogMeta);
    }
    if (data.containsKey('cog')) {
      context.handle(
        _cogMeta,
        cog.isAcceptableOrUnknown(data['cog']!, _cogMeta),
      );
    } else if (isInserting) {
      context.missing(_cogMeta);
    }
    if (data.containsKey('heel')) {
      context.handle(
        _heelMeta,
        heel.isAcceptableOrUnknown(data['heel']!, _heelMeta),
      );
    } else if (isInserting) {
      context.missing(_heelMeta);
    }
    if (data.containsKey('pitch')) {
      context.handle(
        _pitchMeta,
        pitch.isAcceptableOrUnknown(data['pitch']!, _pitchMeta),
      );
    }
    if (data.containsKey('mag_heading')) {
      context.handle(
        _magHeadingMeta,
        magHeading.isAcceptableOrUnknown(data['mag_heading']!, _magHeadingMeta),
      );
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GpsPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GpsPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      sog: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sog'],
      )!,
      cog: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cog'],
      )!,
      heel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heel'],
      )!,
      pitch: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pitch'],
      )!,
      magHeading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mag_heading'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
    );
  }

  @override
  $GpsPointsTable createAlias(String alias) {
    return $GpsPointsTable(attachedDatabase, alias);
  }
}

class GpsPoint extends DataClass implements Insertable<GpsPoint> {
  final String id;
  final String sessionId;
  final DateTime timestamp;
  final double lat;
  final double lon;
  final double sog;
  final double cog;
  final double heel;
  final double pitch;
  final double magHeading;
  final double accuracy;
  const GpsPoint({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.sog,
    required this.cog,
    required this.heel,
    required this.pitch,
    required this.magHeading,
    required this.accuracy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['sog'] = Variable<double>(sog);
    map['cog'] = Variable<double>(cog);
    map['heel'] = Variable<double>(heel);
    map['pitch'] = Variable<double>(pitch);
    map['mag_heading'] = Variable<double>(magHeading);
    map['accuracy'] = Variable<double>(accuracy);
    return map;
  }

  GpsPointsCompanion toCompanion(bool nullToAbsent) {
    return GpsPointsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      timestamp: Value(timestamp),
      lat: Value(lat),
      lon: Value(lon),
      sog: Value(sog),
      cog: Value(cog),
      heel: Value(heel),
      pitch: Value(pitch),
      magHeading: Value(magHeading),
      accuracy: Value(accuracy),
    );
  }

  factory GpsPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GpsPoint(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      sog: serializer.fromJson<double>(json['sog']),
      cog: serializer.fromJson<double>(json['cog']),
      heel: serializer.fromJson<double>(json['heel']),
      pitch: serializer.fromJson<double>(json['pitch']),
      magHeading: serializer.fromJson<double>(json['magHeading']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'sog': serializer.toJson<double>(sog),
      'cog': serializer.toJson<double>(cog),
      'heel': serializer.toJson<double>(heel),
      'pitch': serializer.toJson<double>(pitch),
      'magHeading': serializer.toJson<double>(magHeading),
      'accuracy': serializer.toJson<double>(accuracy),
    };
  }

  GpsPoint copyWith({
    String? id,
    String? sessionId,
    DateTime? timestamp,
    double? lat,
    double? lon,
    double? sog,
    double? cog,
    double? heel,
    double? pitch,
    double? magHeading,
    double? accuracy,
  }) => GpsPoint(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    timestamp: timestamp ?? this.timestamp,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    sog: sog ?? this.sog,
    cog: cog ?? this.cog,
    heel: heel ?? this.heel,
    pitch: pitch ?? this.pitch,
    magHeading: magHeading ?? this.magHeading,
    accuracy: accuracy ?? this.accuracy,
  );
  GpsPoint copyWithCompanion(GpsPointsCompanion data) {
    return GpsPoint(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      sog: data.sog.present ? data.sog.value : this.sog,
      cog: data.cog.present ? data.cog.value : this.cog,
      heel: data.heel.present ? data.heel.value : this.heel,
      pitch: data.pitch.present ? data.pitch.value : this.pitch,
      magHeading: data.magHeading.present
          ? data.magHeading.value
          : this.magHeading,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GpsPoint(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('sog: $sog, ')
          ..write('cog: $cog, ')
          ..write('heel: $heel, ')
          ..write('pitch: $pitch, ')
          ..write('magHeading: $magHeading, ')
          ..write('accuracy: $accuracy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    timestamp,
    lat,
    lon,
    sog,
    cog,
    heel,
    pitch,
    magHeading,
    accuracy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GpsPoint &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.timestamp == this.timestamp &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.sog == this.sog &&
          other.cog == this.cog &&
          other.heel == this.heel &&
          other.pitch == this.pitch &&
          other.magHeading == this.magHeading &&
          other.accuracy == this.accuracy);
}

class GpsPointsCompanion extends UpdateCompanion<GpsPoint> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<DateTime> timestamp;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> sog;
  final Value<double> cog;
  final Value<double> heel;
  final Value<double> pitch;
  final Value<double> magHeading;
  final Value<double> accuracy;
  final Value<int> rowid;
  const GpsPointsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.sog = const Value.absent(),
    this.cog = const Value.absent(),
    this.heel = const Value.absent(),
    this.pitch = const Value.absent(),
    this.magHeading = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GpsPointsCompanion.insert({
    required String id,
    required String sessionId,
    required DateTime timestamp,
    required double lat,
    required double lon,
    required double sog,
    required double cog,
    required double heel,
    this.pitch = const Value.absent(),
    this.magHeading = const Value.absent(),
    required double accuracy,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       timestamp = Value(timestamp),
       lat = Value(lat),
       lon = Value(lon),
       sog = Value(sog),
       cog = Value(cog),
       heel = Value(heel),
       accuracy = Value(accuracy);
  static Insertable<GpsPoint> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<DateTime>? timestamp,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? sog,
    Expression<double>? cog,
    Expression<double>? heel,
    Expression<double>? pitch,
    Expression<double>? magHeading,
    Expression<double>? accuracy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (timestamp != null) 'timestamp': timestamp,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (sog != null) 'sog': sog,
      if (cog != null) 'cog': cog,
      if (heel != null) 'heel': heel,
      if (pitch != null) 'pitch': pitch,
      if (magHeading != null) 'mag_heading': magHeading,
      if (accuracy != null) 'accuracy': accuracy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GpsPointsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<DateTime>? timestamp,
    Value<double>? lat,
    Value<double>? lon,
    Value<double>? sog,
    Value<double>? cog,
    Value<double>? heel,
    Value<double>? pitch,
    Value<double>? magHeading,
    Value<double>? accuracy,
    Value<int>? rowid,
  }) {
    return GpsPointsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      sog: sog ?? this.sog,
      cog: cog ?? this.cog,
      heel: heel ?? this.heel,
      pitch: pitch ?? this.pitch,
      magHeading: magHeading ?? this.magHeading,
      accuracy: accuracy ?? this.accuracy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (sog.present) {
      map['sog'] = Variable<double>(sog.value);
    }
    if (cog.present) {
      map['cog'] = Variable<double>(cog.value);
    }
    if (heel.present) {
      map['heel'] = Variable<double>(heel.value);
    }
    if (pitch.present) {
      map['pitch'] = Variable<double>(pitch.value);
    }
    if (magHeading.present) {
      map['mag_heading'] = Variable<double>(magHeading.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GpsPointsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('sog: $sog, ')
          ..write('cog: $cog, ')
          ..write('heel: $heel, ')
          ..write('pitch: $pitch, ')
          ..write('magHeading: $magHeading, ')
          ..write('accuracy: $accuracy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BoatsTable boats = $BoatsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $GpsPointsTable gpsPoints = $GpsPointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    boats,
    sessions,
    gpsPoints,
  ];
}

typedef $$BoatsTableCreateCompanionBuilder =
    BoatsCompanion Function({
      required String id,
      required String sailNumber,
      required String name,
      required String boatClass,
      required double maxSpeed,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$BoatsTableUpdateCompanionBuilder =
    BoatsCompanion Function({
      Value<String> id,
      Value<String> sailNumber,
      Value<String> name,
      Value<String> boatClass,
      Value<double> maxSpeed,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$BoatsTableReferences
    extends BaseReferences<_$AppDatabase, $BoatsTable, Boat> {
  $$BoatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.boats.id, db.sessions.boatId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.boatId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoatsTableFilterComposer extends Composer<_$AppDatabase, $BoatsTable> {
  $$BoatsTableFilterComposer({
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

  ColumnFilters<String> get sailNumber => $composableBuilder(
    column: $table.sailNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boatClass => $composableBuilder(
    column: $table.boatClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSpeed => $composableBuilder(
    column: $table.maxSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.boatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoatsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoatsTable> {
  $$BoatsTableOrderingComposer({
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

  ColumnOrderings<String> get sailNumber => $composableBuilder(
    column: $table.sailNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boatClass => $composableBuilder(
    column: $table.boatClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSpeed => $composableBuilder(
    column: $table.maxSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoatsTable> {
  $$BoatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sailNumber => $composableBuilder(
    column: $table.sailNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get boatClass =>
      $composableBuilder(column: $table.boatClass, builder: (column) => column);

  GeneratedColumn<double> get maxSpeed =>
      $composableBuilder(column: $table.maxSpeed, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.boatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoatsTable,
          Boat,
          $$BoatsTableFilterComposer,
          $$BoatsTableOrderingComposer,
          $$BoatsTableAnnotationComposer,
          $$BoatsTableCreateCompanionBuilder,
          $$BoatsTableUpdateCompanionBuilder,
          (Boat, $$BoatsTableReferences),
          Boat,
          PrefetchHooks Function({bool sessionsRefs})
        > {
  $$BoatsTableTableManager(_$AppDatabase db, $BoatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sailNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> boatClass = const Value.absent(),
                Value<double> maxSpeed = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoatsCompanion(
                id: id,
                sailNumber: sailNumber,
                name: name,
                boatClass: boatClass,
                maxSpeed: maxSpeed,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sailNumber,
                required String name,
                required String boatClass,
                required double maxSpeed,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoatsCompanion.insert(
                id: id,
                sailNumber: sailNumber,
                name: name,
                boatClass: boatClass,
                maxSpeed: maxSpeed,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BoatsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<Boat, $BoatsTable, Session>(
                      currentTable: table,
                      referencedTable: $$BoatsTableReferences
                          ._sessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BoatsTableReferences(db, table, p0).sessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.boatId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BoatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoatsTable,
      Boat,
      $$BoatsTableFilterComposer,
      $$BoatsTableOrderingComposer,
      $$BoatsTableAnnotationComposer,
      $$BoatsTableCreateCompanionBuilder,
      $$BoatsTableUpdateCompanionBuilder,
      (Boat, $$BoatsTableReferences),
      Boat,
      PrefetchHooks Function({bool sessionsRefs})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String name,
      required String boatId,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<bool> isComplete,
      Value<bool> isSynced,
      Value<double?> distance,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> boatId,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<bool> isComplete,
      Value<bool> isSynced,
      Value<double?> distance,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoatsTable _boatIdTable(_$AppDatabase db) => db.boats.createAlias(
    $_aliasNameGenerator(db.sessions.boatId, db.boats.id),
  );

  $$BoatsTableProcessedTableManager get boatId {
    final $_column = $_itemColumn<String>('boat_id')!;

    final manager = $$BoatsTableTableManager(
      $_db,
      $_db.boats,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boatIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GpsPointsTable, List<GpsPoint>>
  _gpsPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gpsPoints,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.gpsPoints.sessionId),
  );

  $$GpsPointsTableProcessedTableManager get gpsPointsRefs {
    final manager = $$GpsPointsTableTableManager(
      $_db,
      $_db.gpsPoints,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_gpsPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  $$BoatsTableFilterComposer get boatId {
    final $$BoatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boatId,
      referencedTable: $db.boats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoatsTableFilterComposer(
            $db: $db,
            $table: $db.boats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> gpsPointsRefs(
    Expression<bool> Function($$GpsPointsTableFilterComposer f) f,
  ) {
    final $$GpsPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gpsPoints,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GpsPointsTableFilterComposer(
            $db: $db,
            $table: $db.gpsPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoatsTableOrderingComposer get boatId {
    final $$BoatsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boatId,
      referencedTable: $db.boats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoatsTableOrderingComposer(
            $db: $db,
            $table: $db.boats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  $$BoatsTableAnnotationComposer get boatId {
    final $$BoatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boatId,
      referencedTable: $db.boats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoatsTableAnnotationComposer(
            $db: $db,
            $table: $db.boats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> gpsPointsRefs<T extends Object>(
    Expression<T> Function($$GpsPointsTableAnnotationComposer a) f,
  ) {
    final $$GpsPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gpsPoints,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GpsPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.gpsPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool boatId, bool gpsPointsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> boatId = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                name: name,
                boatId: boatId,
                startTime: startTime,
                endTime: endTime,
                isComplete: isComplete,
                isSynced: isSynced,
                distance: distance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String boatId,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                name: name,
                boatId: boatId,
                startTime: startTime,
                endTime: endTime,
                isComplete: isComplete,
                isSynced: isSynced,
                distance: distance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boatId = false, gpsPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gpsPointsRefs) db.gpsPoints],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boatId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boatId,
                                referencedTable: $$SessionsTableReferences
                                    ._boatIdTable(db),
                                referencedColumn: $$SessionsTableReferences
                                    ._boatIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gpsPointsRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      GpsPoint
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._gpsPointsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).gpsPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool boatId, bool gpsPointsRefs})
    >;
typedef $$GpsPointsTableCreateCompanionBuilder =
    GpsPointsCompanion Function({
      required String id,
      required String sessionId,
      required DateTime timestamp,
      required double lat,
      required double lon,
      required double sog,
      required double cog,
      required double heel,
      Value<double> pitch,
      Value<double> magHeading,
      required double accuracy,
      Value<int> rowid,
    });
typedef $$GpsPointsTableUpdateCompanionBuilder =
    GpsPointsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<DateTime> timestamp,
      Value<double> lat,
      Value<double> lon,
      Value<double> sog,
      Value<double> cog,
      Value<double> heel,
      Value<double> pitch,
      Value<double> magHeading,
      Value<double> accuracy,
      Value<int> rowid,
    });

final class $$GpsPointsTableReferences
    extends BaseReferences<_$AppDatabase, $GpsPointsTable, GpsPoint> {
  $$GpsPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.gpsPoints.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GpsPointsTableFilterComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sog => $composableBuilder(
    column: $table.sog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cog => $composableBuilder(
    column: $table.cog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heel => $composableBuilder(
    column: $table.heel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pitch => $composableBuilder(
    column: $table.pitch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get magHeading => $composableBuilder(
    column: $table.magHeading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GpsPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sog => $composableBuilder(
    column: $table.sog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cog => $composableBuilder(
    column: $table.cog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heel => $composableBuilder(
    column: $table.heel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pitch => $composableBuilder(
    column: $table.pitch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get magHeading => $composableBuilder(
    column: $table.magHeading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GpsPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GpsPointsTable> {
  $$GpsPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get sog =>
      $composableBuilder(column: $table.sog, builder: (column) => column);

  GeneratedColumn<double> get cog =>
      $composableBuilder(column: $table.cog, builder: (column) => column);

  GeneratedColumn<double> get heel =>
      $composableBuilder(column: $table.heel, builder: (column) => column);

  GeneratedColumn<double> get pitch =>
      $composableBuilder(column: $table.pitch, builder: (column) => column);

  GeneratedColumn<double> get magHeading => $composableBuilder(
    column: $table.magHeading,
    builder: (column) => column,
  );

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GpsPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GpsPointsTable,
          GpsPoint,
          $$GpsPointsTableFilterComposer,
          $$GpsPointsTableOrderingComposer,
          $$GpsPointsTableAnnotationComposer,
          $$GpsPointsTableCreateCompanionBuilder,
          $$GpsPointsTableUpdateCompanionBuilder,
          (GpsPoint, $$GpsPointsTableReferences),
          GpsPoint,
          PrefetchHooks Function({bool sessionId})
        > {
  $$GpsPointsTableTableManager(_$AppDatabase db, $GpsPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GpsPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GpsPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GpsPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double> sog = const Value.absent(),
                Value<double> cog = const Value.absent(),
                Value<double> heel = const Value.absent(),
                Value<double> pitch = const Value.absent(),
                Value<double> magHeading = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GpsPointsCompanion(
                id: id,
                sessionId: sessionId,
                timestamp: timestamp,
                lat: lat,
                lon: lon,
                sog: sog,
                cog: cog,
                heel: heel,
                pitch: pitch,
                magHeading: magHeading,
                accuracy: accuracy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required DateTime timestamp,
                required double lat,
                required double lon,
                required double sog,
                required double cog,
                required double heel,
                Value<double> pitch = const Value.absent(),
                Value<double> magHeading = const Value.absent(),
                required double accuracy,
                Value<int> rowid = const Value.absent(),
              }) => GpsPointsCompanion.insert(
                id: id,
                sessionId: sessionId,
                timestamp: timestamp,
                lat: lat,
                lon: lon,
                sog: sog,
                cog: cog,
                heel: heel,
                pitch: pitch,
                magHeading: magHeading,
                accuracy: accuracy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GpsPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$GpsPointsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$GpsPointsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GpsPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GpsPointsTable,
      GpsPoint,
      $$GpsPointsTableFilterComposer,
      $$GpsPointsTableOrderingComposer,
      $$GpsPointsTableAnnotationComposer,
      $$GpsPointsTableCreateCompanionBuilder,
      $$GpsPointsTableUpdateCompanionBuilder,
      (GpsPoint, $$GpsPointsTableReferences),
      GpsPoint,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BoatsTableTableManager get boats =>
      $$BoatsTableTableManager(_db, _db.boats);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$GpsPointsTableTableManager get gpsPoints =>
      $$GpsPointsTableTableManager(_db, _db.gpsPoints);
}
