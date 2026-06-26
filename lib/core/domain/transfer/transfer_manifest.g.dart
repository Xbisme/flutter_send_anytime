// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ManifestFileEntry _$ManifestFileEntryFromJson(Map<String, dynamic> json) =>
    _ManifestFileEntry(
      index: (json['index'] as num).toInt(),
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      mime: json['mime'] as String?,
    );

Map<String, dynamic> _$ManifestFileEntryToJson(_ManifestFileEntry instance) =>
    <String, dynamic>{
      'index': instance.index,
      'name': instance.name,
      'size': instance.size,
      'mime': instance.mime,
    };

_TransferManifest _$TransferManifestFromJson(Map<String, dynamic> json) =>
    _TransferManifest(
      v: (json['v'] as num).toInt(),
      sessionId: json['sessionId'] as String,
      fileCount: (json['fileCount'] as num).toInt(),
      totalBytes: (json['totalBytes'] as num).toInt(),
      files: (json['files'] as List<dynamic>)
          .map((e) => ManifestFileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      senderName: json['senderName'] as String?,
    );

Map<String, dynamic> _$TransferManifestToJson(_TransferManifest instance) =>
    <String, dynamic>{
      'v': instance.v,
      'sessionId': instance.sessionId,
      'fileCount': instance.fileCount,
      'totalBytes': instance.totalBytes,
      'files': instance.files,
      'senderName': instance.senderName,
    };
