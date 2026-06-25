// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransferRecordsTable extends TransferRecords
    with TableInfo<$TransferRecordsTable, TransferRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
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
  static const VerificationMeta _pairingMethodMeta = const VerificationMeta(
    'pairingMethod',
  );
  @override
  late final GeneratedColumn<String> pairingMethod = GeneratedColumn<String>(
    'pairing_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerLabelMeta = const VerificationMeta(
    'peerLabel',
  );
  @override
  late final GeneratedColumn<String> peerLabel = GeneratedColumn<String>(
    'peer_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fileCountMeta = const VerificationMeta(
    'fileCount',
  );
  @override
  late final GeneratedColumn<int> fileCount = GeneratedColumn<int>(
    'file_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    direction,
    status,
    pairingMethod,
    peerLabel,
    fileCount,
    totalBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('pairing_method')) {
      context.handle(
        _pairingMethodMeta,
        pairingMethod.isAcceptableOrUnknown(
          data['pairing_method']!,
          _pairingMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pairingMethodMeta);
    }
    if (data.containsKey('peer_label')) {
      context.handle(
        _peerLabelMeta,
        peerLabel.isAcceptableOrUnknown(data['peer_label']!, _peerLabelMeta),
      );
    }
    if (data.containsKey('file_count')) {
      context.handle(
        _fileCountMeta,
        fileCount.isAcceptableOrUnknown(data['file_count']!, _fileCountMeta),
      );
    } else if (isInserting) {
      context.missing(_fileCountMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
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
  TransferRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pairingMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pairing_method'],
      )!,
      peerLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_label'],
      )!,
      fileCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_count'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransferRecordsTable createAlias(String alias) {
    return $TransferRecordsTable(attachedDatabase, alias);
  }
}

class TransferRecordRow extends DataClass
    implements Insertable<TransferRecordRow> {
  /// UUID primary key.
  final String id;

  /// `TransferDirection` name (`sent` / `received`).
  final String direction;

  /// `TransferRecordStatus` name.
  final String status;

  /// `PairingMethod` name.
  final String pairingMethod;

  /// Generic peer label; empty until real device names arrive (#010).
  final String peerLabel;

  /// Number of files offered in the transfer.
  final int fileCount;

  /// Sum of offered file sizes (bytes).
  final int totalBytes;

  /// Terminal-state timestamp (UTC).
  final DateTime createdAt;
  const TransferRecordRow({
    required this.id,
    required this.direction,
    required this.status,
    required this.pairingMethod,
    required this.peerLabel,
    required this.fileCount,
    required this.totalBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['direction'] = Variable<String>(direction);
    map['status'] = Variable<String>(status);
    map['pairing_method'] = Variable<String>(pairingMethod);
    map['peer_label'] = Variable<String>(peerLabel);
    map['file_count'] = Variable<int>(fileCount);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransferRecordsCompanion toCompanion(bool nullToAbsent) {
    return TransferRecordsCompanion(
      id: Value(id),
      direction: Value(direction),
      status: Value(status),
      pairingMethod: Value(pairingMethod),
      peerLabel: Value(peerLabel),
      fileCount: Value(fileCount),
      totalBytes: Value(totalBytes),
      createdAt: Value(createdAt),
    );
  }

  factory TransferRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferRecordRow(
      id: serializer.fromJson<String>(json['id']),
      direction: serializer.fromJson<String>(json['direction']),
      status: serializer.fromJson<String>(json['status']),
      pairingMethod: serializer.fromJson<String>(json['pairingMethod']),
      peerLabel: serializer.fromJson<String>(json['peerLabel']),
      fileCount: serializer.fromJson<int>(json['fileCount']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'direction': serializer.toJson<String>(direction),
      'status': serializer.toJson<String>(status),
      'pairingMethod': serializer.toJson<String>(pairingMethod),
      'peerLabel': serializer.toJson<String>(peerLabel),
      'fileCount': serializer.toJson<int>(fileCount),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransferRecordRow copyWith({
    String? id,
    String? direction,
    String? status,
    String? pairingMethod,
    String? peerLabel,
    int? fileCount,
    int? totalBytes,
    DateTime? createdAt,
  }) => TransferRecordRow(
    id: id ?? this.id,
    direction: direction ?? this.direction,
    status: status ?? this.status,
    pairingMethod: pairingMethod ?? this.pairingMethod,
    peerLabel: peerLabel ?? this.peerLabel,
    fileCount: fileCount ?? this.fileCount,
    totalBytes: totalBytes ?? this.totalBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  TransferRecordRow copyWithCompanion(TransferRecordsCompanion data) {
    return TransferRecordRow(
      id: data.id.present ? data.id.value : this.id,
      direction: data.direction.present ? data.direction.value : this.direction,
      status: data.status.present ? data.status.value : this.status,
      pairingMethod: data.pairingMethod.present
          ? data.pairingMethod.value
          : this.pairingMethod,
      peerLabel: data.peerLabel.present ? data.peerLabel.value : this.peerLabel,
      fileCount: data.fileCount.present ? data.fileCount.value : this.fileCount,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferRecordRow(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('pairingMethod: $pairingMethod, ')
          ..write('peerLabel: $peerLabel, ')
          ..write('fileCount: $fileCount, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    direction,
    status,
    pairingMethod,
    peerLabel,
    fileCount,
    totalBytes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferRecordRow &&
          other.id == this.id &&
          other.direction == this.direction &&
          other.status == this.status &&
          other.pairingMethod == this.pairingMethod &&
          other.peerLabel == this.peerLabel &&
          other.fileCount == this.fileCount &&
          other.totalBytes == this.totalBytes &&
          other.createdAt == this.createdAt);
}

class TransferRecordsCompanion extends UpdateCompanion<TransferRecordRow> {
  final Value<String> id;
  final Value<String> direction;
  final Value<String> status;
  final Value<String> pairingMethod;
  final Value<String> peerLabel;
  final Value<int> fileCount;
  final Value<int> totalBytes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransferRecordsCompanion({
    this.id = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    this.pairingMethod = const Value.absent(),
    this.peerLabel = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferRecordsCompanion.insert({
    required String id,
    required String direction,
    required String status,
    required String pairingMethod,
    this.peerLabel = const Value.absent(),
    required int fileCount,
    required int totalBytes,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       direction = Value(direction),
       status = Value(status),
       pairingMethod = Value(pairingMethod),
       fileCount = Value(fileCount),
       totalBytes = Value(totalBytes),
       createdAt = Value(createdAt);
  static Insertable<TransferRecordRow> custom({
    Expression<String>? id,
    Expression<String>? direction,
    Expression<String>? status,
    Expression<String>? pairingMethod,
    Expression<String>? peerLabel,
    Expression<int>? fileCount,
    Expression<int>? totalBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direction != null) 'direction': direction,
      if (status != null) 'status': status,
      if (pairingMethod != null) 'pairing_method': pairingMethod,
      if (peerLabel != null) 'peer_label': peerLabel,
      if (fileCount != null) 'file_count': fileCount,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? direction,
    Value<String>? status,
    Value<String>? pairingMethod,
    Value<String>? peerLabel,
    Value<int>? fileCount,
    Value<int>? totalBytes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TransferRecordsCompanion(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      pairingMethod: pairingMethod ?? this.pairingMethod,
      peerLabel: peerLabel ?? this.peerLabel,
      fileCount: fileCount ?? this.fileCount,
      totalBytes: totalBytes ?? this.totalBytes,
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
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pairingMethod.present) {
      map['pairing_method'] = Variable<String>(pairingMethod.value);
    }
    if (peerLabel.present) {
      map['peer_label'] = Variable<String>(peerLabel.value);
    }
    if (fileCount.present) {
      map['file_count'] = Variable<int>(fileCount.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
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
    return (StringBuffer('TransferRecordsCompanion(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('pairingMethod: $pairingMethod, ')
          ..write('peerLabel: $peerLabel, ')
          ..write('fileCount: $fileCount, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferRecordFilesTable extends TransferRecordFiles
    with TableInfo<$TransferRecordFilesTable, TransferRecordFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferRecordFilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transfer_records (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _includedMeta = const VerificationMeta(
    'included',
  );
  @override
  late final GeneratedColumn<bool> included = GeneratedColumn<bool>(
    'included',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("included" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordId,
    name,
    mimeType,
    size,
    path,
    included,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_record_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferRecordFileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    }
    if (data.containsKey('included')) {
      context.handle(
        _includedMeta,
        included.isAcceptableOrUnknown(data['included']!, _includedMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferRecordFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferRecordFileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      ),
      included: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}included'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $TransferRecordFilesTable createAlias(String alias) {
    return $TransferRecordFilesTable(attachedDatabase, alias);
  }
}

class TransferRecordFileRow extends DataClass
    implements Insertable<TransferRecordFileRow> {
  /// Auto-increment surrogate key.
  final int id;

  /// Owning record id.
  final String recordId;

  /// File basename (no directory component).
  final String name;

  /// Best-effort content type, or null.
  final String? mimeType;

  /// File size in bytes.
  final int size;

  /// Source path (sent — for re-send existence) / final path (received — for
  /// open); null when unknown. Read-only; never used to write.
  final String? path;

  /// Whether this file completed and was kept in the transfer (FR-013a).
  final bool included;

  /// Manifest position, to preserve order in the detail list.
  final int position;
  const TransferRecordFileRow({
    required this.id,
    required this.recordId,
    required this.name,
    this.mimeType,
    required this.size,
    this.path,
    required this.included,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['record_id'] = Variable<String>(recordId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['size'] = Variable<int>(size);
    if (!nullToAbsent || path != null) {
      map['path'] = Variable<String>(path);
    }
    map['included'] = Variable<bool>(included);
    map['position'] = Variable<int>(position);
    return map;
  }

  TransferRecordFilesCompanion toCompanion(bool nullToAbsent) {
    return TransferRecordFilesCompanion(
      id: Value(id),
      recordId: Value(recordId),
      name: Value(name),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      size: Value(size),
      path: path == null && nullToAbsent ? const Value.absent() : Value(path),
      included: Value(included),
      position: Value(position),
    );
  }

  factory TransferRecordFileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferRecordFileRow(
      id: serializer.fromJson<int>(json['id']),
      recordId: serializer.fromJson<String>(json['recordId']),
      name: serializer.fromJson<String>(json['name']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      size: serializer.fromJson<int>(json['size']),
      path: serializer.fromJson<String?>(json['path']),
      included: serializer.fromJson<bool>(json['included']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordId': serializer.toJson<String>(recordId),
      'name': serializer.toJson<String>(name),
      'mimeType': serializer.toJson<String?>(mimeType),
      'size': serializer.toJson<int>(size),
      'path': serializer.toJson<String?>(path),
      'included': serializer.toJson<bool>(included),
      'position': serializer.toJson<int>(position),
    };
  }

  TransferRecordFileRow copyWith({
    int? id,
    String? recordId,
    String? name,
    Value<String?> mimeType = const Value.absent(),
    int? size,
    Value<String?> path = const Value.absent(),
    bool? included,
    int? position,
  }) => TransferRecordFileRow(
    id: id ?? this.id,
    recordId: recordId ?? this.recordId,
    name: name ?? this.name,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    size: size ?? this.size,
    path: path.present ? path.value : this.path,
    included: included ?? this.included,
    position: position ?? this.position,
  );
  TransferRecordFileRow copyWithCompanion(TransferRecordFilesCompanion data) {
    return TransferRecordFileRow(
      id: data.id.present ? data.id.value : this.id,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      name: data.name.present ? data.name.value : this.name,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      size: data.size.present ? data.size.value : this.size,
      path: data.path.present ? data.path.value : this.path,
      included: data.included.present ? data.included.value : this.included,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferRecordFileRow(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('name: $name, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('path: $path, ')
          ..write('included: $included, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recordId, name, mimeType, size, path, included, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferRecordFileRow &&
          other.id == this.id &&
          other.recordId == this.recordId &&
          other.name == this.name &&
          other.mimeType == this.mimeType &&
          other.size == this.size &&
          other.path == this.path &&
          other.included == this.included &&
          other.position == this.position);
}

class TransferRecordFilesCompanion
    extends UpdateCompanion<TransferRecordFileRow> {
  final Value<int> id;
  final Value<String> recordId;
  final Value<String> name;
  final Value<String?> mimeType;
  final Value<int> size;
  final Value<String?> path;
  final Value<bool> included;
  final Value<int> position;
  const TransferRecordFilesCompanion({
    this.id = const Value.absent(),
    this.recordId = const Value.absent(),
    this.name = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.size = const Value.absent(),
    this.path = const Value.absent(),
    this.included = const Value.absent(),
    this.position = const Value.absent(),
  });
  TransferRecordFilesCompanion.insert({
    this.id = const Value.absent(),
    required String recordId,
    required String name,
    this.mimeType = const Value.absent(),
    required int size,
    this.path = const Value.absent(),
    this.included = const Value.absent(),
    required int position,
  }) : recordId = Value(recordId),
       name = Value(name),
       size = Value(size),
       position = Value(position);
  static Insertable<TransferRecordFileRow> custom({
    Expression<int>? id,
    Expression<String>? recordId,
    Expression<String>? name,
    Expression<String>? mimeType,
    Expression<int>? size,
    Expression<String>? path,
    Expression<bool>? included,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordId != null) 'record_id': recordId,
      if (name != null) 'name': name,
      if (mimeType != null) 'mime_type': mimeType,
      if (size != null) 'size': size,
      if (path != null) 'path': path,
      if (included != null) 'included': included,
      if (position != null) 'position': position,
    });
  }

  TransferRecordFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? recordId,
    Value<String>? name,
    Value<String?>? mimeType,
    Value<int>? size,
    Value<String?>? path,
    Value<bool>? included,
    Value<int>? position,
  }) {
    return TransferRecordFilesCompanion(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      path: path ?? this.path,
      included: included ?? this.included,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (included.present) {
      map['included'] = Variable<bool>(included.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferRecordFilesCompanion(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('name: $name, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('path: $path, ')
          ..write('included: $included, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransferRecordsTable transferRecords = $TransferRecordsTable(
    this,
  );
  late final $TransferRecordFilesTable transferRecordFiles =
      $TransferRecordFilesTable(this);
  late final TransferHistoryDao transferHistoryDao = TransferHistoryDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transferRecords,
    transferRecordFiles,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transfer_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transfer_record_files', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TransferRecordsTableCreateCompanionBuilder =
    TransferRecordsCompanion Function({
      required String id,
      required String direction,
      required String status,
      required String pairingMethod,
      Value<String> peerLabel,
      required int fileCount,
      required int totalBytes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TransferRecordsTableUpdateCompanionBuilder =
    TransferRecordsCompanion Function({
      Value<String> id,
      Value<String> direction,
      Value<String> status,
      Value<String> pairingMethod,
      Value<String> peerLabel,
      Value<int> fileCount,
      Value<int> totalBytes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TransferRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransferRecordsTable,
          TransferRecordRow
        > {
  $$TransferRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $TransferRecordFilesTable,
    List<TransferRecordFileRow>
  >
  _transferRecordFilesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transferRecordFiles,
        aliasName: 'transfer_records__id__transfer_record_files__record_id',
      );

  $$TransferRecordFilesTableProcessedTableManager get transferRecordFilesRefs {
    final manager = $$TransferRecordFilesTableTableManager(
      $_db,
      $_db.transferRecordFiles,
    ).filter((f) => f.recordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transferRecordFilesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransferRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $TransferRecordsTable> {
  $$TransferRecordsTableFilterComposer({
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

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pairingMethod => $composableBuilder(
    column: $table.pairingMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerLabel => $composableBuilder(
    column: $table.peerLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transferRecordFilesRefs(
    Expression<bool> Function($$TransferRecordFilesTableFilterComposer f) f,
  ) {
    final $$TransferRecordFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transferRecordFiles,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferRecordFilesTableFilterComposer(
            $db: $db,
            $table: $db.transferRecordFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransferRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferRecordsTable> {
  $$TransferRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pairingMethod => $composableBuilder(
    column: $table.pairingMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerLabel => $composableBuilder(
    column: $table.peerLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransferRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferRecordsTable> {
  $$TransferRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get pairingMethod => $composableBuilder(
    column: $table.pairingMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerLabel =>
      $composableBuilder(column: $table.peerLabel, builder: (column) => column);

  GeneratedColumn<int> get fileCount =>
      $composableBuilder(column: $table.fileCount, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> transferRecordFilesRefs<T extends Object>(
    Expression<T> Function($$TransferRecordFilesTableAnnotationComposer a) f,
  ) {
    final $$TransferRecordFilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transferRecordFiles,
          getReferencedColumn: (t) => t.recordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransferRecordFilesTableAnnotationComposer(
                $db: $db,
                $table: $db.transferRecordFiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TransferRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferRecordsTable,
          TransferRecordRow,
          $$TransferRecordsTableFilterComposer,
          $$TransferRecordsTableOrderingComposer,
          $$TransferRecordsTableAnnotationComposer,
          $$TransferRecordsTableCreateCompanionBuilder,
          $$TransferRecordsTableUpdateCompanionBuilder,
          (TransferRecordRow, $$TransferRecordsTableReferences),
          TransferRecordRow,
          PrefetchHooks Function({bool transferRecordFilesRefs})
        > {
  $$TransferRecordsTableTableManager(
    _$AppDatabase db,
    $TransferRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> pairingMethod = const Value.absent(),
                Value<String> peerLabel = const Value.absent(),
                Value<int> fileCount = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferRecordsCompanion(
                id: id,
                direction: direction,
                status: status,
                pairingMethod: pairingMethod,
                peerLabel: peerLabel,
                fileCount: fileCount,
                totalBytes: totalBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String direction,
                required String status,
                required String pairingMethod,
                Value<String> peerLabel = const Value.absent(),
                required int fileCount,
                required int totalBytes,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TransferRecordsCompanion.insert(
                id: id,
                direction: direction,
                status: status,
                pairingMethod: pairingMethod,
                peerLabel: peerLabel,
                fileCount: fileCount,
                totalBytes: totalBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransferRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transferRecordFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transferRecordFilesRefs) db.transferRecordFiles,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transferRecordFilesRefs)
                    await $_getPrefetchedData<
                      TransferRecordRow,
                      $TransferRecordsTable,
                      TransferRecordFileRow
                    >(
                      currentTable: table,
                      referencedTable: $$TransferRecordsTableReferences
                          ._transferRecordFilesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TransferRecordsTableReferences(
                            db,
                            table,
                            p0,
                          ).transferRecordFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.recordId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TransferRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferRecordsTable,
      TransferRecordRow,
      $$TransferRecordsTableFilterComposer,
      $$TransferRecordsTableOrderingComposer,
      $$TransferRecordsTableAnnotationComposer,
      $$TransferRecordsTableCreateCompanionBuilder,
      $$TransferRecordsTableUpdateCompanionBuilder,
      (TransferRecordRow, $$TransferRecordsTableReferences),
      TransferRecordRow,
      PrefetchHooks Function({bool transferRecordFilesRefs})
    >;
typedef $$TransferRecordFilesTableCreateCompanionBuilder =
    TransferRecordFilesCompanion Function({
      Value<int> id,
      required String recordId,
      required String name,
      Value<String?> mimeType,
      required int size,
      Value<String?> path,
      Value<bool> included,
      required int position,
    });
typedef $$TransferRecordFilesTableUpdateCompanionBuilder =
    TransferRecordFilesCompanion Function({
      Value<int> id,
      Value<String> recordId,
      Value<String> name,
      Value<String?> mimeType,
      Value<int> size,
      Value<String?> path,
      Value<bool> included,
      Value<int> position,
    });

final class $$TransferRecordFilesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransferRecordFilesTable,
          TransferRecordFileRow
        > {
  $$TransferRecordFilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransferRecordsTable _recordIdTable(_$AppDatabase db) => db
      .transferRecords
      .createAlias('transfer_record_files__record_id__transfer_records__id');

  $$TransferRecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<String>('record_id')!;

    final manager = $$TransferRecordsTableTableManager(
      $_db,
      $_db.transferRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransferRecordFilesTableFilterComposer
    extends Composer<_$AppDatabase, $TransferRecordFilesTable> {
  $$TransferRecordFilesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get included => $composableBuilder(
    column: $table.included,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$TransferRecordsTableFilterComposer get recordId {
    final $$TransferRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.transferRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferRecordsTableFilterComposer(
            $db: $db,
            $table: $db.transferRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferRecordFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferRecordFilesTable> {
  $$TransferRecordFilesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get included => $composableBuilder(
    column: $table.included,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransferRecordsTableOrderingComposer get recordId {
    final $$TransferRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.transferRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.transferRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferRecordFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferRecordFilesTable> {
  $$TransferRecordFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get included =>
      $composableBuilder(column: $table.included, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$TransferRecordsTableAnnotationComposer get recordId {
    final $$TransferRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.transferRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.transferRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferRecordFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferRecordFilesTable,
          TransferRecordFileRow,
          $$TransferRecordFilesTableFilterComposer,
          $$TransferRecordFilesTableOrderingComposer,
          $$TransferRecordFilesTableAnnotationComposer,
          $$TransferRecordFilesTableCreateCompanionBuilder,
          $$TransferRecordFilesTableUpdateCompanionBuilder,
          (TransferRecordFileRow, $$TransferRecordFilesTableReferences),
          TransferRecordFileRow,
          PrefetchHooks Function({bool recordId})
        > {
  $$TransferRecordFilesTableTableManager(
    _$AppDatabase db,
    $TransferRecordFilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferRecordFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferRecordFilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransferRecordFilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String?> path = const Value.absent(),
                Value<bool> included = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => TransferRecordFilesCompanion(
                id: id,
                recordId: recordId,
                name: name,
                mimeType: mimeType,
                size: size,
                path: path,
                included: included,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String recordId,
                required String name,
                Value<String?> mimeType = const Value.absent(),
                required int size,
                Value<String?> path = const Value.absent(),
                Value<bool> included = const Value.absent(),
                required int position,
              }) => TransferRecordFilesCompanion.insert(
                id: id,
                recordId: recordId,
                name: name,
                mimeType: mimeType,
                size: size,
                path: path,
                included: included,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransferRecordFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordId = false}) {
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
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable:
                                    $$TransferRecordFilesTableReferences
                                        ._recordIdTable(db),
                                referencedColumn:
                                    $$TransferRecordFilesTableReferences
                                        ._recordIdTable(db)
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

typedef $$TransferRecordFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferRecordFilesTable,
      TransferRecordFileRow,
      $$TransferRecordFilesTableFilterComposer,
      $$TransferRecordFilesTableOrderingComposer,
      $$TransferRecordFilesTableAnnotationComposer,
      $$TransferRecordFilesTableCreateCompanionBuilder,
      $$TransferRecordFilesTableUpdateCompanionBuilder,
      (TransferRecordFileRow, $$TransferRecordFilesTableReferences),
      TransferRecordFileRow,
      PrefetchHooks Function({bool recordId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransferRecordsTableTableManager get transferRecords =>
      $$TransferRecordsTableTableManager(_db, _db.transferRecords);
  $$TransferRecordFilesTableTableManager get transferRecordFiles =>
      $$TransferRecordFilesTableTableManager(_db, _db.transferRecordFiles);
}
