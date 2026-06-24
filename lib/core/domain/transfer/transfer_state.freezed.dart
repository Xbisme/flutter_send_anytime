// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransferProgress {

 int get overallBytesTransferred; int get overallTotalBytes; int? get currentFileIndex; int get currentFileBytesTransferred; int get currentFileTotalBytes;
/// Create a copy of TransferProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferProgressCopyWith<TransferProgress> get copyWith => _$TransferProgressCopyWithImpl<TransferProgress>(this as TransferProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferProgress&&(identical(other.overallBytesTransferred, overallBytesTransferred) || other.overallBytesTransferred == overallBytesTransferred)&&(identical(other.overallTotalBytes, overallTotalBytes) || other.overallTotalBytes == overallTotalBytes)&&(identical(other.currentFileIndex, currentFileIndex) || other.currentFileIndex == currentFileIndex)&&(identical(other.currentFileBytesTransferred, currentFileBytesTransferred) || other.currentFileBytesTransferred == currentFileBytesTransferred)&&(identical(other.currentFileTotalBytes, currentFileTotalBytes) || other.currentFileTotalBytes == currentFileTotalBytes));
}


@override
int get hashCode => Object.hash(runtimeType,overallBytesTransferred,overallTotalBytes,currentFileIndex,currentFileBytesTransferred,currentFileTotalBytes);

@override
String toString() {
  return 'TransferProgress(overallBytesTransferred: $overallBytesTransferred, overallTotalBytes: $overallTotalBytes, currentFileIndex: $currentFileIndex, currentFileBytesTransferred: $currentFileBytesTransferred, currentFileTotalBytes: $currentFileTotalBytes)';
}


}

/// @nodoc
abstract mixin class $TransferProgressCopyWith<$Res>  {
  factory $TransferProgressCopyWith(TransferProgress value, $Res Function(TransferProgress) _then) = _$TransferProgressCopyWithImpl;
@useResult
$Res call({
 int overallBytesTransferred, int overallTotalBytes, int? currentFileIndex, int currentFileBytesTransferred, int currentFileTotalBytes
});




}
/// @nodoc
class _$TransferProgressCopyWithImpl<$Res>
    implements $TransferProgressCopyWith<$Res> {
  _$TransferProgressCopyWithImpl(this._self, this._then);

  final TransferProgress _self;
  final $Res Function(TransferProgress) _then;

/// Create a copy of TransferProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallBytesTransferred = null,Object? overallTotalBytes = null,Object? currentFileIndex = freezed,Object? currentFileBytesTransferred = null,Object? currentFileTotalBytes = null,}) {
  return _then(_self.copyWith(
overallBytesTransferred: null == overallBytesTransferred ? _self.overallBytesTransferred : overallBytesTransferred // ignore: cast_nullable_to_non_nullable
as int,overallTotalBytes: null == overallTotalBytes ? _self.overallTotalBytes : overallTotalBytes // ignore: cast_nullable_to_non_nullable
as int,currentFileIndex: freezed == currentFileIndex ? _self.currentFileIndex : currentFileIndex // ignore: cast_nullable_to_non_nullable
as int?,currentFileBytesTransferred: null == currentFileBytesTransferred ? _self.currentFileBytesTransferred : currentFileBytesTransferred // ignore: cast_nullable_to_non_nullable
as int,currentFileTotalBytes: null == currentFileTotalBytes ? _self.currentFileTotalBytes : currentFileTotalBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TransferProgress].
extension TransferProgressPatterns on TransferProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferProgress value)  $default,){
final _that = this;
switch (_that) {
case _TransferProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferProgress value)?  $default,){
final _that = this;
switch (_that) {
case _TransferProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int overallBytesTransferred,  int overallTotalBytes,  int? currentFileIndex,  int currentFileBytesTransferred,  int currentFileTotalBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferProgress() when $default != null:
return $default(_that.overallBytesTransferred,_that.overallTotalBytes,_that.currentFileIndex,_that.currentFileBytesTransferred,_that.currentFileTotalBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int overallBytesTransferred,  int overallTotalBytes,  int? currentFileIndex,  int currentFileBytesTransferred,  int currentFileTotalBytes)  $default,) {final _that = this;
switch (_that) {
case _TransferProgress():
return $default(_that.overallBytesTransferred,_that.overallTotalBytes,_that.currentFileIndex,_that.currentFileBytesTransferred,_that.currentFileTotalBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int overallBytesTransferred,  int overallTotalBytes,  int? currentFileIndex,  int currentFileBytesTransferred,  int currentFileTotalBytes)?  $default,) {final _that = this;
switch (_that) {
case _TransferProgress() when $default != null:
return $default(_that.overallBytesTransferred,_that.overallTotalBytes,_that.currentFileIndex,_that.currentFileBytesTransferred,_that.currentFileTotalBytes);case _:
  return null;

}
}

}

/// @nodoc


class _TransferProgress implements TransferProgress {
  const _TransferProgress({this.overallBytesTransferred = 0, this.overallTotalBytes = 0, this.currentFileIndex, this.currentFileBytesTransferred = 0, this.currentFileTotalBytes = 0});
  

@override@JsonKey() final  int overallBytesTransferred;
@override@JsonKey() final  int overallTotalBytes;
@override final  int? currentFileIndex;
@override@JsonKey() final  int currentFileBytesTransferred;
@override@JsonKey() final  int currentFileTotalBytes;

/// Create a copy of TransferProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferProgressCopyWith<_TransferProgress> get copyWith => __$TransferProgressCopyWithImpl<_TransferProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferProgress&&(identical(other.overallBytesTransferred, overallBytesTransferred) || other.overallBytesTransferred == overallBytesTransferred)&&(identical(other.overallTotalBytes, overallTotalBytes) || other.overallTotalBytes == overallTotalBytes)&&(identical(other.currentFileIndex, currentFileIndex) || other.currentFileIndex == currentFileIndex)&&(identical(other.currentFileBytesTransferred, currentFileBytesTransferred) || other.currentFileBytesTransferred == currentFileBytesTransferred)&&(identical(other.currentFileTotalBytes, currentFileTotalBytes) || other.currentFileTotalBytes == currentFileTotalBytes));
}


@override
int get hashCode => Object.hash(runtimeType,overallBytesTransferred,overallTotalBytes,currentFileIndex,currentFileBytesTransferred,currentFileTotalBytes);

@override
String toString() {
  return 'TransferProgress(overallBytesTransferred: $overallBytesTransferred, overallTotalBytes: $overallTotalBytes, currentFileIndex: $currentFileIndex, currentFileBytesTransferred: $currentFileBytesTransferred, currentFileTotalBytes: $currentFileTotalBytes)';
}


}

/// @nodoc
abstract mixin class _$TransferProgressCopyWith<$Res> implements $TransferProgressCopyWith<$Res> {
  factory _$TransferProgressCopyWith(_TransferProgress value, $Res Function(_TransferProgress) _then) = __$TransferProgressCopyWithImpl;
@override @useResult
$Res call({
 int overallBytesTransferred, int overallTotalBytes, int? currentFileIndex, int currentFileBytesTransferred, int currentFileTotalBytes
});




}
/// @nodoc
class __$TransferProgressCopyWithImpl<$Res>
    implements _$TransferProgressCopyWith<$Res> {
  __$TransferProgressCopyWithImpl(this._self, this._then);

  final _TransferProgress _self;
  final $Res Function(_TransferProgress) _then;

/// Create a copy of TransferProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallBytesTransferred = null,Object? overallTotalBytes = null,Object? currentFileIndex = freezed,Object? currentFileBytesTransferred = null,Object? currentFileTotalBytes = null,}) {
  return _then(_TransferProgress(
overallBytesTransferred: null == overallBytesTransferred ? _self.overallBytesTransferred : overallBytesTransferred // ignore: cast_nullable_to_non_nullable
as int,overallTotalBytes: null == overallTotalBytes ? _self.overallTotalBytes : overallTotalBytes // ignore: cast_nullable_to_non_nullable
as int,currentFileIndex: freezed == currentFileIndex ? _self.currentFileIndex : currentFileIndex // ignore: cast_nullable_to_non_nullable
as int?,currentFileBytesTransferred: null == currentFileBytesTransferred ? _self.currentFileBytesTransferred : currentFileBytesTransferred // ignore: cast_nullable_to_non_nullable
as int,currentFileTotalBytes: null == currentFileTotalBytes ? _self.currentFileTotalBytes : currentFileTotalBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TransferSnapshot {

 TransferPhase get phase; TransferRole get role; TransferProgress get progress; List<FileTransferItem> get items; AppFailure? get failure;
/// Create a copy of TransferSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferSnapshotCopyWith<TransferSnapshot> get copyWith => _$TransferSnapshotCopyWithImpl<TransferSnapshot>(this as TransferSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferSnapshot&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.role, role) || other.role == role)&&(identical(other.progress, progress) || other.progress == progress)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,phase,role,progress,const DeepCollectionEquality().hash(items),failure);

@override
String toString() {
  return 'TransferSnapshot(phase: $phase, role: $role, progress: $progress, items: $items, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TransferSnapshotCopyWith<$Res>  {
  factory $TransferSnapshotCopyWith(TransferSnapshot value, $Res Function(TransferSnapshot) _then) = _$TransferSnapshotCopyWithImpl;
@useResult
$Res call({
 TransferPhase phase, TransferRole role, TransferProgress progress, List<FileTransferItem> items, AppFailure? failure
});


$TransferProgressCopyWith<$Res> get progress;$AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$TransferSnapshotCopyWithImpl<$Res>
    implements $TransferSnapshotCopyWith<$Res> {
  _$TransferSnapshotCopyWithImpl(this._self, this._then);

  final TransferSnapshot _self;
  final $Res Function(TransferSnapshot) _then;

/// Create a copy of TransferSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? role = null,Object? progress = null,Object? items = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TransferPhase,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TransferRole,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as TransferProgress,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FileTransferItem>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}
/// Create a copy of TransferSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransferProgressCopyWith<$Res> get progress {
  
  return $TransferProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of TransferSnapshot
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


/// Adds pattern-matching-related methods to [TransferSnapshot].
extension TransferSnapshotPatterns on TransferSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _TransferSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _TransferSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransferPhase phase,  TransferRole role,  TransferProgress progress,  List<FileTransferItem> items,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferSnapshot() when $default != null:
return $default(_that.phase,_that.role,_that.progress,_that.items,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransferPhase phase,  TransferRole role,  TransferProgress progress,  List<FileTransferItem> items,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _TransferSnapshot():
return $default(_that.phase,_that.role,_that.progress,_that.items,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransferPhase phase,  TransferRole role,  TransferProgress progress,  List<FileTransferItem> items,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _TransferSnapshot() when $default != null:
return $default(_that.phase,_that.role,_that.progress,_that.items,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _TransferSnapshot extends TransferSnapshot {
  const _TransferSnapshot({required this.phase, required this.role, required this.progress, final  List<FileTransferItem> items = const <FileTransferItem>[], this.failure}): _items = items,super._();
  

@override final  TransferPhase phase;
@override final  TransferRole role;
@override final  TransferProgress progress;
 final  List<FileTransferItem> _items;
@override@JsonKey() List<FileTransferItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  AppFailure? failure;

/// Create a copy of TransferSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferSnapshotCopyWith<_TransferSnapshot> get copyWith => __$TransferSnapshotCopyWithImpl<_TransferSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferSnapshot&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.role, role) || other.role == role)&&(identical(other.progress, progress) || other.progress == progress)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,phase,role,progress,const DeepCollectionEquality().hash(_items),failure);

@override
String toString() {
  return 'TransferSnapshot(phase: $phase, role: $role, progress: $progress, items: $items, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$TransferSnapshotCopyWith<$Res> implements $TransferSnapshotCopyWith<$Res> {
  factory _$TransferSnapshotCopyWith(_TransferSnapshot value, $Res Function(_TransferSnapshot) _then) = __$TransferSnapshotCopyWithImpl;
@override @useResult
$Res call({
 TransferPhase phase, TransferRole role, TransferProgress progress, List<FileTransferItem> items, AppFailure? failure
});


@override $TransferProgressCopyWith<$Res> get progress;@override $AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$TransferSnapshotCopyWithImpl<$Res>
    implements _$TransferSnapshotCopyWith<$Res> {
  __$TransferSnapshotCopyWithImpl(this._self, this._then);

  final _TransferSnapshot _self;
  final $Res Function(_TransferSnapshot) _then;

/// Create a copy of TransferSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? role = null,Object? progress = null,Object? items = null,Object? failure = freezed,}) {
  return _then(_TransferSnapshot(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TransferPhase,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TransferRole,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as TransferProgress,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<FileTransferItem>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

/// Create a copy of TransferSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransferProgressCopyWith<$Res> get progress {
  
  return $TransferProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of TransferSnapshot
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
