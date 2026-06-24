// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_transfer_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FileTransferItem {

 int get index; String get name; int get size; String? get mimeType; String? get sha256; int get bytesTransferred; FileItemStatus get status; AppFailure? get failure; String? get quarantinePath; String? get finalPath;
/// Create a copy of FileTransferItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileTransferItemCopyWith<FileTransferItem> get copyWith => _$FileTransferItemCopyWithImpl<FileTransferItem>(this as FileTransferItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileTransferItem&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.bytesTransferred, bytesTransferred) || other.bytesTransferred == bytesTransferred)&&(identical(other.status, status) || other.status == status)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.quarantinePath, quarantinePath) || other.quarantinePath == quarantinePath)&&(identical(other.finalPath, finalPath) || other.finalPath == finalPath));
}


@override
int get hashCode => Object.hash(runtimeType,index,name,size,mimeType,sha256,bytesTransferred,status,failure,quarantinePath,finalPath);

@override
String toString() {
  return 'FileTransferItem(index: $index, name: $name, size: $size, mimeType: $mimeType, sha256: $sha256, bytesTransferred: $bytesTransferred, status: $status, failure: $failure, quarantinePath: $quarantinePath, finalPath: $finalPath)';
}


}

/// @nodoc
abstract mixin class $FileTransferItemCopyWith<$Res>  {
  factory $FileTransferItemCopyWith(FileTransferItem value, $Res Function(FileTransferItem) _then) = _$FileTransferItemCopyWithImpl;
@useResult
$Res call({
 int index, String name, int size, String? mimeType, String? sha256, int bytesTransferred, FileItemStatus status, AppFailure? failure, String? quarantinePath, String? finalPath
});


$AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$FileTransferItemCopyWithImpl<$Res>
    implements $FileTransferItemCopyWith<$Res> {
  _$FileTransferItemCopyWithImpl(this._self, this._then);

  final FileTransferItem _self;
  final $Res Function(FileTransferItem) _then;

/// Create a copy of FileTransferItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? name = null,Object? size = null,Object? mimeType = freezed,Object? sha256 = freezed,Object? bytesTransferred = null,Object? status = null,Object? failure = freezed,Object? quarantinePath = freezed,Object? finalPath = freezed,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,bytesTransferred: null == bytesTransferred ? _self.bytesTransferred : bytesTransferred // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FileItemStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,quarantinePath: freezed == quarantinePath ? _self.quarantinePath : quarantinePath // ignore: cast_nullable_to_non_nullable
as String?,finalPath: freezed == finalPath ? _self.finalPath : finalPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FileTransferItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [FileTransferItem].
extension FileTransferItemPatterns on FileTransferItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileTransferItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileTransferItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileTransferItem value)  $default,){
final _that = this;
switch (_that) {
case _FileTransferItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileTransferItem value)?  $default,){
final _that = this;
switch (_that) {
case _FileTransferItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String name,  int size,  String? mimeType,  String? sha256,  int bytesTransferred,  FileItemStatus status,  AppFailure? failure,  String? quarantinePath,  String? finalPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileTransferItem() when $default != null:
return $default(_that.index,_that.name,_that.size,_that.mimeType,_that.sha256,_that.bytesTransferred,_that.status,_that.failure,_that.quarantinePath,_that.finalPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String name,  int size,  String? mimeType,  String? sha256,  int bytesTransferred,  FileItemStatus status,  AppFailure? failure,  String? quarantinePath,  String? finalPath)  $default,) {final _that = this;
switch (_that) {
case _FileTransferItem():
return $default(_that.index,_that.name,_that.size,_that.mimeType,_that.sha256,_that.bytesTransferred,_that.status,_that.failure,_that.quarantinePath,_that.finalPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String name,  int size,  String? mimeType,  String? sha256,  int bytesTransferred,  FileItemStatus status,  AppFailure? failure,  String? quarantinePath,  String? finalPath)?  $default,) {final _that = this;
switch (_that) {
case _FileTransferItem() when $default != null:
return $default(_that.index,_that.name,_that.size,_that.mimeType,_that.sha256,_that.bytesTransferred,_that.status,_that.failure,_that.quarantinePath,_that.finalPath);case _:
  return null;

}
}

}

/// @nodoc


class _FileTransferItem extends FileTransferItem {
  const _FileTransferItem({required this.index, required this.name, required this.size, this.mimeType, this.sha256, this.bytesTransferred = 0, this.status = FileItemStatus.pending, this.failure, this.quarantinePath, this.finalPath}): super._();
  

@override final  int index;
@override final  String name;
@override final  int size;
@override final  String? mimeType;
@override final  String? sha256;
@override@JsonKey() final  int bytesTransferred;
@override@JsonKey() final  FileItemStatus status;
@override final  AppFailure? failure;
@override final  String? quarantinePath;
@override final  String? finalPath;

/// Create a copy of FileTransferItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileTransferItemCopyWith<_FileTransferItem> get copyWith => __$FileTransferItemCopyWithImpl<_FileTransferItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileTransferItem&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.bytesTransferred, bytesTransferred) || other.bytesTransferred == bytesTransferred)&&(identical(other.status, status) || other.status == status)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.quarantinePath, quarantinePath) || other.quarantinePath == quarantinePath)&&(identical(other.finalPath, finalPath) || other.finalPath == finalPath));
}


@override
int get hashCode => Object.hash(runtimeType,index,name,size,mimeType,sha256,bytesTransferred,status,failure,quarantinePath,finalPath);

@override
String toString() {
  return 'FileTransferItem(index: $index, name: $name, size: $size, mimeType: $mimeType, sha256: $sha256, bytesTransferred: $bytesTransferred, status: $status, failure: $failure, quarantinePath: $quarantinePath, finalPath: $finalPath)';
}


}

/// @nodoc
abstract mixin class _$FileTransferItemCopyWith<$Res> implements $FileTransferItemCopyWith<$Res> {
  factory _$FileTransferItemCopyWith(_FileTransferItem value, $Res Function(_FileTransferItem) _then) = __$FileTransferItemCopyWithImpl;
@override @useResult
$Res call({
 int index, String name, int size, String? mimeType, String? sha256, int bytesTransferred, FileItemStatus status, AppFailure? failure, String? quarantinePath, String? finalPath
});


@override $AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$FileTransferItemCopyWithImpl<$Res>
    implements _$FileTransferItemCopyWith<$Res> {
  __$FileTransferItemCopyWithImpl(this._self, this._then);

  final _FileTransferItem _self;
  final $Res Function(_FileTransferItem) _then;

/// Create a copy of FileTransferItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? name = null,Object? size = null,Object? mimeType = freezed,Object? sha256 = freezed,Object? bytesTransferred = null,Object? status = null,Object? failure = freezed,Object? quarantinePath = freezed,Object? finalPath = freezed,}) {
  return _then(_FileTransferItem(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,bytesTransferred: null == bytesTransferred ? _self.bytesTransferred : bytesTransferred // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FileItemStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,quarantinePath: freezed == quarantinePath ? _self.quarantinePath : quarantinePath // ignore: cast_nullable_to_non_nullable
as String?,finalPath: freezed == finalPath ? _self.finalPath : finalPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FileTransferItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
