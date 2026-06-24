// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ManifestFileEntry {

 int get index; String get name; int get size; String? get mime;
/// Create a copy of ManifestFileEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManifestFileEntryCopyWith<ManifestFileEntry> get copyWith => _$ManifestFileEntryCopyWithImpl<ManifestFileEntry>(this as ManifestFileEntry, _$identity);

  /// Serializes this ManifestFileEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManifestFileEntry&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mime, mime) || other.mime == mime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,size,mime);

@override
String toString() {
  return 'ManifestFileEntry(index: $index, name: $name, size: $size, mime: $mime)';
}


}

/// @nodoc
abstract mixin class $ManifestFileEntryCopyWith<$Res>  {
  factory $ManifestFileEntryCopyWith(ManifestFileEntry value, $Res Function(ManifestFileEntry) _then) = _$ManifestFileEntryCopyWithImpl;
@useResult
$Res call({
 int index, String name, int size, String? mime
});




}
/// @nodoc
class _$ManifestFileEntryCopyWithImpl<$Res>
    implements $ManifestFileEntryCopyWith<$Res> {
  _$ManifestFileEntryCopyWithImpl(this._self, this._then);

  final ManifestFileEntry _self;
  final $Res Function(ManifestFileEntry) _then;

/// Create a copy of ManifestFileEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? name = null,Object? size = null,Object? mime = freezed,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ManifestFileEntry].
extension ManifestFileEntryPatterns on ManifestFileEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ManifestFileEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ManifestFileEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ManifestFileEntry value)  $default,){
final _that = this;
switch (_that) {
case _ManifestFileEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ManifestFileEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ManifestFileEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String name,  int size,  String? mime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ManifestFileEntry() when $default != null:
return $default(_that.index,_that.name,_that.size,_that.mime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String name,  int size,  String? mime)  $default,) {final _that = this;
switch (_that) {
case _ManifestFileEntry():
return $default(_that.index,_that.name,_that.size,_that.mime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String name,  int size,  String? mime)?  $default,) {final _that = this;
switch (_that) {
case _ManifestFileEntry() when $default != null:
return $default(_that.index,_that.name,_that.size,_that.mime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ManifestFileEntry implements ManifestFileEntry {
  const _ManifestFileEntry({required this.index, required this.name, required this.size, this.mime});
  factory _ManifestFileEntry.fromJson(Map<String, dynamic> json) => _$ManifestFileEntryFromJson(json);

@override final  int index;
@override final  String name;
@override final  int size;
@override final  String? mime;

/// Create a copy of ManifestFileEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManifestFileEntryCopyWith<_ManifestFileEntry> get copyWith => __$ManifestFileEntryCopyWithImpl<_ManifestFileEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ManifestFileEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManifestFileEntry&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mime, mime) || other.mime == mime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,size,mime);

@override
String toString() {
  return 'ManifestFileEntry(index: $index, name: $name, size: $size, mime: $mime)';
}


}

/// @nodoc
abstract mixin class _$ManifestFileEntryCopyWith<$Res> implements $ManifestFileEntryCopyWith<$Res> {
  factory _$ManifestFileEntryCopyWith(_ManifestFileEntry value, $Res Function(_ManifestFileEntry) _then) = __$ManifestFileEntryCopyWithImpl;
@override @useResult
$Res call({
 int index, String name, int size, String? mime
});




}
/// @nodoc
class __$ManifestFileEntryCopyWithImpl<$Res>
    implements _$ManifestFileEntryCopyWith<$Res> {
  __$ManifestFileEntryCopyWithImpl(this._self, this._then);

  final _ManifestFileEntry _self;
  final $Res Function(_ManifestFileEntry) _then;

/// Create a copy of ManifestFileEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? name = null,Object? size = null,Object? mime = freezed,}) {
  return _then(_ManifestFileEntry(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TransferManifest {

 int get v; String get sessionId; int get fileCount; int get totalBytes; List<ManifestFileEntry> get files;
/// Create a copy of TransferManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferManifestCopyWith<TransferManifest> get copyWith => _$TransferManifestCopyWithImpl<TransferManifest>(this as TransferManifest, _$identity);

  /// Serializes this TransferManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferManifest&&(identical(other.v, v) || other.v == v)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&const DeepCollectionEquality().equals(other.files, files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,v,sessionId,fileCount,totalBytes,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'TransferManifest(v: $v, sessionId: $sessionId, fileCount: $fileCount, totalBytes: $totalBytes, files: $files)';
}


}

/// @nodoc
abstract mixin class $TransferManifestCopyWith<$Res>  {
  factory $TransferManifestCopyWith(TransferManifest value, $Res Function(TransferManifest) _then) = _$TransferManifestCopyWithImpl;
@useResult
$Res call({
 int v, String sessionId, int fileCount, int totalBytes, List<ManifestFileEntry> files
});




}
/// @nodoc
class _$TransferManifestCopyWithImpl<$Res>
    implements $TransferManifestCopyWith<$Res> {
  _$TransferManifestCopyWithImpl(this._self, this._then);

  final TransferManifest _self;
  final $Res Function(TransferManifest) _then;

/// Create a copy of TransferManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? v = null,Object? sessionId = null,Object? fileCount = null,Object? totalBytes = null,Object? files = null,}) {
  return _then(_self.copyWith(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<ManifestFileEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [TransferManifest].
extension TransferManifestPatterns on TransferManifest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferManifest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferManifest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferManifest value)  $default,){
final _that = this;
switch (_that) {
case _TransferManifest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferManifest value)?  $default,){
final _that = this;
switch (_that) {
case _TransferManifest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int v,  String sessionId,  int fileCount,  int totalBytes,  List<ManifestFileEntry> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferManifest() when $default != null:
return $default(_that.v,_that.sessionId,_that.fileCount,_that.totalBytes,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int v,  String sessionId,  int fileCount,  int totalBytes,  List<ManifestFileEntry> files)  $default,) {final _that = this;
switch (_that) {
case _TransferManifest():
return $default(_that.v,_that.sessionId,_that.fileCount,_that.totalBytes,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int v,  String sessionId,  int fileCount,  int totalBytes,  List<ManifestFileEntry> files)?  $default,) {final _that = this;
switch (_that) {
case _TransferManifest() when $default != null:
return $default(_that.v,_that.sessionId,_that.fileCount,_that.totalBytes,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransferManifest extends TransferManifest {
  const _TransferManifest({required this.v, required this.sessionId, required this.fileCount, required this.totalBytes, required final  List<ManifestFileEntry> files}): _files = files,super._();
  factory _TransferManifest.fromJson(Map<String, dynamic> json) => _$TransferManifestFromJson(json);

@override final  int v;
@override final  String sessionId;
@override final  int fileCount;
@override final  int totalBytes;
 final  List<ManifestFileEntry> _files;
@override List<ManifestFileEntry> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of TransferManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferManifestCopyWith<_TransferManifest> get copyWith => __$TransferManifestCopyWithImpl<_TransferManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransferManifestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferManifest&&(identical(other.v, v) || other.v == v)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&const DeepCollectionEquality().equals(other._files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,v,sessionId,fileCount,totalBytes,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'TransferManifest(v: $v, sessionId: $sessionId, fileCount: $fileCount, totalBytes: $totalBytes, files: $files)';
}


}

/// @nodoc
abstract mixin class _$TransferManifestCopyWith<$Res> implements $TransferManifestCopyWith<$Res> {
  factory _$TransferManifestCopyWith(_TransferManifest value, $Res Function(_TransferManifest) _then) = __$TransferManifestCopyWithImpl;
@override @useResult
$Res call({
 int v, String sessionId, int fileCount, int totalBytes, List<ManifestFileEntry> files
});




}
/// @nodoc
class __$TransferManifestCopyWithImpl<$Res>
    implements _$TransferManifestCopyWith<$Res> {
  __$TransferManifestCopyWithImpl(this._self, this._then);

  final _TransferManifest _self;
  final $Res Function(_TransferManifest) _then;

/// Create a copy of TransferManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? v = null,Object? sessionId = null,Object? fileCount = null,Object? totalBytes = null,Object? files = null,}) {
  return _then(_TransferManifest(
v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<ManifestFileEntry>,
  ));
}


}

// dart format on
