// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransferRecord {

 String get id; TransferDirection get direction; TransferRecordStatus get status; PairingMethod get pairingMethod; int get fileCount; int get totalBytes; DateTime get createdAt; String get peerLabel; List<RecordedFile> get files;
/// Create a copy of TransferRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferRecordCopyWith<TransferRecord> get copyWith => _$TransferRecordCopyWithImpl<TransferRecord>(this as TransferRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.status, status) || other.status == status)&&(identical(other.pairingMethod, pairingMethod) || other.pairingMethod == pairingMethod)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.peerLabel, peerLabel) || other.peerLabel == peerLabel)&&const DeepCollectionEquality().equals(other.files, files));
}


@override
int get hashCode => Object.hash(runtimeType,id,direction,status,pairingMethod,fileCount,totalBytes,createdAt,peerLabel,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'TransferRecord(id: $id, direction: $direction, status: $status, pairingMethod: $pairingMethod, fileCount: $fileCount, totalBytes: $totalBytes, createdAt: $createdAt, peerLabel: $peerLabel, files: $files)';
}


}

/// @nodoc
abstract mixin class $TransferRecordCopyWith<$Res>  {
  factory $TransferRecordCopyWith(TransferRecord value, $Res Function(TransferRecord) _then) = _$TransferRecordCopyWithImpl;
@useResult
$Res call({
 String id, TransferDirection direction, TransferRecordStatus status, PairingMethod pairingMethod, int fileCount, int totalBytes, DateTime createdAt, String peerLabel, List<RecordedFile> files
});




}
/// @nodoc
class _$TransferRecordCopyWithImpl<$Res>
    implements $TransferRecordCopyWith<$Res> {
  _$TransferRecordCopyWithImpl(this._self, this._then);

  final TransferRecord _self;
  final $Res Function(TransferRecord) _then;

/// Create a copy of TransferRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? direction = null,Object? status = null,Object? pairingMethod = null,Object? fileCount = null,Object? totalBytes = null,Object? createdAt = null,Object? peerLabel = null,Object? files = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TransferDirection,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferRecordStatus,pairingMethod: null == pairingMethod ? _self.pairingMethod : pairingMethod // ignore: cast_nullable_to_non_nullable
as PairingMethod,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,peerLabel: null == peerLabel ? _self.peerLabel : peerLabel // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<RecordedFile>,
  ));
}

}


/// Adds pattern-matching-related methods to [TransferRecord].
extension TransferRecordPatterns on TransferRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferRecord value)  $default,){
final _that = this;
switch (_that) {
case _TransferRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferRecord value)?  $default,){
final _that = this;
switch (_that) {
case _TransferRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TransferDirection direction,  TransferRecordStatus status,  PairingMethod pairingMethod,  int fileCount,  int totalBytes,  DateTime createdAt,  String peerLabel,  List<RecordedFile> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferRecord() when $default != null:
return $default(_that.id,_that.direction,_that.status,_that.pairingMethod,_that.fileCount,_that.totalBytes,_that.createdAt,_that.peerLabel,_that.files);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TransferDirection direction,  TransferRecordStatus status,  PairingMethod pairingMethod,  int fileCount,  int totalBytes,  DateTime createdAt,  String peerLabel,  List<RecordedFile> files)  $default,) {final _that = this;
switch (_that) {
case _TransferRecord():
return $default(_that.id,_that.direction,_that.status,_that.pairingMethod,_that.fileCount,_that.totalBytes,_that.createdAt,_that.peerLabel,_that.files);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TransferDirection direction,  TransferRecordStatus status,  PairingMethod pairingMethod,  int fileCount,  int totalBytes,  DateTime createdAt,  String peerLabel,  List<RecordedFile> files)?  $default,) {final _that = this;
switch (_that) {
case _TransferRecord() when $default != null:
return $default(_that.id,_that.direction,_that.status,_that.pairingMethod,_that.fileCount,_that.totalBytes,_that.createdAt,_that.peerLabel,_that.files);case _:
  return null;

}
}

}

/// @nodoc


class _TransferRecord extends TransferRecord {
  const _TransferRecord({required this.id, required this.direction, required this.status, required this.pairingMethod, required this.fileCount, required this.totalBytes, required this.createdAt, this.peerLabel = '', final  List<RecordedFile> files = const <RecordedFile>[]}): _files = files,super._();
  

@override final  String id;
@override final  TransferDirection direction;
@override final  TransferRecordStatus status;
@override final  PairingMethod pairingMethod;
@override final  int fileCount;
@override final  int totalBytes;
@override final  DateTime createdAt;
@override@JsonKey() final  String peerLabel;
 final  List<RecordedFile> _files;
@override@JsonKey() List<RecordedFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of TransferRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferRecordCopyWith<_TransferRecord> get copyWith => __$TransferRecordCopyWithImpl<_TransferRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.status, status) || other.status == status)&&(identical(other.pairingMethod, pairingMethod) || other.pairingMethod == pairingMethod)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.peerLabel, peerLabel) || other.peerLabel == peerLabel)&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,id,direction,status,pairingMethod,fileCount,totalBytes,createdAt,peerLabel,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'TransferRecord(id: $id, direction: $direction, status: $status, pairingMethod: $pairingMethod, fileCount: $fileCount, totalBytes: $totalBytes, createdAt: $createdAt, peerLabel: $peerLabel, files: $files)';
}


}

/// @nodoc
abstract mixin class _$TransferRecordCopyWith<$Res> implements $TransferRecordCopyWith<$Res> {
  factory _$TransferRecordCopyWith(_TransferRecord value, $Res Function(_TransferRecord) _then) = __$TransferRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, TransferDirection direction, TransferRecordStatus status, PairingMethod pairingMethod, int fileCount, int totalBytes, DateTime createdAt, String peerLabel, List<RecordedFile> files
});




}
/// @nodoc
class __$TransferRecordCopyWithImpl<$Res>
    implements _$TransferRecordCopyWith<$Res> {
  __$TransferRecordCopyWithImpl(this._self, this._then);

  final _TransferRecord _self;
  final $Res Function(_TransferRecord) _then;

/// Create a copy of TransferRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? direction = null,Object? status = null,Object? pairingMethod = null,Object? fileCount = null,Object? totalBytes = null,Object? createdAt = null,Object? peerLabel = null,Object? files = null,}) {
  return _then(_TransferRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TransferDirection,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferRecordStatus,pairingMethod: null == pairingMethod ? _self.pairingMethod : pairingMethod // ignore: cast_nullable_to_non_nullable
as PairingMethod,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,peerLabel: null == peerLabel ? _self.peerLabel : peerLabel // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<RecordedFile>,
  ));
}


}

/// @nodoc
mixin _$RecordedFile {

 String get name; int get size; String? get mimeType; String? get path; bool get included;
/// Create a copy of RecordedFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordedFileCopyWith<RecordedFile> get copyWith => _$RecordedFileCopyWithImpl<RecordedFile>(this as RecordedFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordedFile&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.path, path) || other.path == path)&&(identical(other.included, included) || other.included == included));
}


@override
int get hashCode => Object.hash(runtimeType,name,size,mimeType,path,included);

@override
String toString() {
  return 'RecordedFile(name: $name, size: $size, mimeType: $mimeType, path: $path, included: $included)';
}


}

/// @nodoc
abstract mixin class $RecordedFileCopyWith<$Res>  {
  factory $RecordedFileCopyWith(RecordedFile value, $Res Function(RecordedFile) _then) = _$RecordedFileCopyWithImpl;
@useResult
$Res call({
 String name, int size, String? mimeType, String? path, bool included
});




}
/// @nodoc
class _$RecordedFileCopyWithImpl<$Res>
    implements $RecordedFileCopyWith<$Res> {
  _$RecordedFileCopyWithImpl(this._self, this._then);

  final RecordedFile _self;
  final $Res Function(RecordedFile) _then;

/// Create a copy of RecordedFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? size = null,Object? mimeType = freezed,Object? path = freezed,Object? included = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,included: null == included ? _self.included : included // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RecordedFile].
extension RecordedFilePatterns on RecordedFile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecordedFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecordedFile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecordedFile value)  $default,){
final _that = this;
switch (_that) {
case _RecordedFile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecordedFile value)?  $default,){
final _that = this;
switch (_that) {
case _RecordedFile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int size,  String? mimeType,  String? path,  bool included)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecordedFile() when $default != null:
return $default(_that.name,_that.size,_that.mimeType,_that.path,_that.included);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int size,  String? mimeType,  String? path,  bool included)  $default,) {final _that = this;
switch (_that) {
case _RecordedFile():
return $default(_that.name,_that.size,_that.mimeType,_that.path,_that.included);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int size,  String? mimeType,  String? path,  bool included)?  $default,) {final _that = this;
switch (_that) {
case _RecordedFile() when $default != null:
return $default(_that.name,_that.size,_that.mimeType,_that.path,_that.included);case _:
  return null;

}
}

}

/// @nodoc


class _RecordedFile extends RecordedFile {
  const _RecordedFile({required this.name, required this.size, this.mimeType, this.path, this.included = true}): super._();
  

@override final  String name;
@override final  int size;
@override final  String? mimeType;
@override final  String? path;
@override@JsonKey() final  bool included;

/// Create a copy of RecordedFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecordedFileCopyWith<_RecordedFile> get copyWith => __$RecordedFileCopyWithImpl<_RecordedFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecordedFile&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.path, path) || other.path == path)&&(identical(other.included, included) || other.included == included));
}


@override
int get hashCode => Object.hash(runtimeType,name,size,mimeType,path,included);

@override
String toString() {
  return 'RecordedFile(name: $name, size: $size, mimeType: $mimeType, path: $path, included: $included)';
}


}

/// @nodoc
abstract mixin class _$RecordedFileCopyWith<$Res> implements $RecordedFileCopyWith<$Res> {
  factory _$RecordedFileCopyWith(_RecordedFile value, $Res Function(_RecordedFile) _then) = __$RecordedFileCopyWithImpl;
@override @useResult
$Res call({
 String name, int size, String? mimeType, String? path, bool included
});




}
/// @nodoc
class __$RecordedFileCopyWithImpl<$Res>
    implements _$RecordedFileCopyWith<$Res> {
  __$RecordedFileCopyWithImpl(this._self, this._then);

  final _RecordedFile _self;
  final $Res Function(_RecordedFile) _then;

/// Create a copy of RecordedFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? size = null,Object? mimeType = freezed,Object? path = freezed,Object? included = null,}) {
  return _then(_RecordedFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,included: null == included ? _self.included : included // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
