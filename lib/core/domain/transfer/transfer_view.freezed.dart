// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransferView {

 TransferPhase get phase; TransferRole get role; double get overallProgress; int get bytesDone; int get bytesTotal; double get speedBytesPerSec; int? get etaSeconds; int? get currentIndex; String? get currentFileName; int get fileCount; List<FileTransferItem> get items; Duration get elapsed; bool get awaitingDecision; IncomingOffer? get incomingOffer; AppFailure? get failure;
/// Create a copy of TransferView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferViewCopyWith<TransferView> get copyWith => _$TransferViewCopyWithImpl<TransferView>(this as TransferView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferView&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.role, role) || other.role == role)&&(identical(other.overallProgress, overallProgress) || other.overallProgress == overallProgress)&&(identical(other.bytesDone, bytesDone) || other.bytesDone == bytesDone)&&(identical(other.bytesTotal, bytesTotal) || other.bytesTotal == bytesTotal)&&(identical(other.speedBytesPerSec, speedBytesPerSec) || other.speedBytesPerSec == speedBytesPerSec)&&(identical(other.etaSeconds, etaSeconds) || other.etaSeconds == etaSeconds)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.currentFileName, currentFileName) || other.currentFileName == currentFileName)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.awaitingDecision, awaitingDecision) || other.awaitingDecision == awaitingDecision)&&(identical(other.incomingOffer, incomingOffer) || other.incomingOffer == incomingOffer)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,phase,role,overallProgress,bytesDone,bytesTotal,speedBytesPerSec,etaSeconds,currentIndex,currentFileName,fileCount,const DeepCollectionEquality().hash(items),elapsed,awaitingDecision,incomingOffer,failure);

@override
String toString() {
  return 'TransferView(phase: $phase, role: $role, overallProgress: $overallProgress, bytesDone: $bytesDone, bytesTotal: $bytesTotal, speedBytesPerSec: $speedBytesPerSec, etaSeconds: $etaSeconds, currentIndex: $currentIndex, currentFileName: $currentFileName, fileCount: $fileCount, items: $items, elapsed: $elapsed, awaitingDecision: $awaitingDecision, incomingOffer: $incomingOffer, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TransferViewCopyWith<$Res>  {
  factory $TransferViewCopyWith(TransferView value, $Res Function(TransferView) _then) = _$TransferViewCopyWithImpl;
@useResult
$Res call({
 TransferPhase phase, TransferRole role, double overallProgress, int bytesDone, int bytesTotal, double speedBytesPerSec, int? etaSeconds, int? currentIndex, String? currentFileName, int fileCount, List<FileTransferItem> items, Duration elapsed, bool awaitingDecision, IncomingOffer? incomingOffer, AppFailure? failure
});


$IncomingOfferCopyWith<$Res>? get incomingOffer;$AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$TransferViewCopyWithImpl<$Res>
    implements $TransferViewCopyWith<$Res> {
  _$TransferViewCopyWithImpl(this._self, this._then);

  final TransferView _self;
  final $Res Function(TransferView) _then;

/// Create a copy of TransferView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? role = null,Object? overallProgress = null,Object? bytesDone = null,Object? bytesTotal = null,Object? speedBytesPerSec = null,Object? etaSeconds = freezed,Object? currentIndex = freezed,Object? currentFileName = freezed,Object? fileCount = null,Object? items = null,Object? elapsed = null,Object? awaitingDecision = null,Object? incomingOffer = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TransferPhase,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TransferRole,overallProgress: null == overallProgress ? _self.overallProgress : overallProgress // ignore: cast_nullable_to_non_nullable
as double,bytesDone: null == bytesDone ? _self.bytesDone : bytesDone // ignore: cast_nullable_to_non_nullable
as int,bytesTotal: null == bytesTotal ? _self.bytesTotal : bytesTotal // ignore: cast_nullable_to_non_nullable
as int,speedBytesPerSec: null == speedBytesPerSec ? _self.speedBytesPerSec : speedBytesPerSec // ignore: cast_nullable_to_non_nullable
as double,etaSeconds: freezed == etaSeconds ? _self.etaSeconds : etaSeconds // ignore: cast_nullable_to_non_nullable
as int?,currentIndex: freezed == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int?,currentFileName: freezed == currentFileName ? _self.currentFileName : currentFileName // ignore: cast_nullable_to_non_nullable
as String?,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FileTransferItem>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,awaitingDecision: null == awaitingDecision ? _self.awaitingDecision : awaitingDecision // ignore: cast_nullable_to_non_nullable
as bool,incomingOffer: freezed == incomingOffer ? _self.incomingOffer : incomingOffer // ignore: cast_nullable_to_non_nullable
as IncomingOffer?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}
/// Create a copy of TransferView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncomingOfferCopyWith<$Res>? get incomingOffer {
    if (_self.incomingOffer == null) {
    return null;
  }

  return $IncomingOfferCopyWith<$Res>(_self.incomingOffer!, (value) {
    return _then(_self.copyWith(incomingOffer: value));
  });
}/// Create a copy of TransferView
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


/// Adds pattern-matching-related methods to [TransferView].
extension TransferViewPatterns on TransferView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferView value)  $default,){
final _that = this;
switch (_that) {
case _TransferView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferView value)?  $default,){
final _that = this;
switch (_that) {
case _TransferView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransferPhase phase,  TransferRole role,  double overallProgress,  int bytesDone,  int bytesTotal,  double speedBytesPerSec,  int? etaSeconds,  int? currentIndex,  String? currentFileName,  int fileCount,  List<FileTransferItem> items,  Duration elapsed,  bool awaitingDecision,  IncomingOffer? incomingOffer,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferView() when $default != null:
return $default(_that.phase,_that.role,_that.overallProgress,_that.bytesDone,_that.bytesTotal,_that.speedBytesPerSec,_that.etaSeconds,_that.currentIndex,_that.currentFileName,_that.fileCount,_that.items,_that.elapsed,_that.awaitingDecision,_that.incomingOffer,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransferPhase phase,  TransferRole role,  double overallProgress,  int bytesDone,  int bytesTotal,  double speedBytesPerSec,  int? etaSeconds,  int? currentIndex,  String? currentFileName,  int fileCount,  List<FileTransferItem> items,  Duration elapsed,  bool awaitingDecision,  IncomingOffer? incomingOffer,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _TransferView():
return $default(_that.phase,_that.role,_that.overallProgress,_that.bytesDone,_that.bytesTotal,_that.speedBytesPerSec,_that.etaSeconds,_that.currentIndex,_that.currentFileName,_that.fileCount,_that.items,_that.elapsed,_that.awaitingDecision,_that.incomingOffer,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransferPhase phase,  TransferRole role,  double overallProgress,  int bytesDone,  int bytesTotal,  double speedBytesPerSec,  int? etaSeconds,  int? currentIndex,  String? currentFileName,  int fileCount,  List<FileTransferItem> items,  Duration elapsed,  bool awaitingDecision,  IncomingOffer? incomingOffer,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _TransferView() when $default != null:
return $default(_that.phase,_that.role,_that.overallProgress,_that.bytesDone,_that.bytesTotal,_that.speedBytesPerSec,_that.etaSeconds,_that.currentIndex,_that.currentFileName,_that.fileCount,_that.items,_that.elapsed,_that.awaitingDecision,_that.incomingOffer,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _TransferView extends TransferView {
  const _TransferView({required this.phase, required this.role, this.overallProgress = 0, this.bytesDone = 0, this.bytesTotal = 0, this.speedBytesPerSec = 0, this.etaSeconds, this.currentIndex, this.currentFileName, this.fileCount = 0, final  List<FileTransferItem> items = const <FileTransferItem>[], this.elapsed = Duration.zero, this.awaitingDecision = false, this.incomingOffer, this.failure}): _items = items,super._();
  

@override final  TransferPhase phase;
@override final  TransferRole role;
@override@JsonKey() final  double overallProgress;
@override@JsonKey() final  int bytesDone;
@override@JsonKey() final  int bytesTotal;
@override@JsonKey() final  double speedBytesPerSec;
@override final  int? etaSeconds;
@override final  int? currentIndex;
@override final  String? currentFileName;
@override@JsonKey() final  int fileCount;
 final  List<FileTransferItem> _items;
@override@JsonKey() List<FileTransferItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  Duration elapsed;
@override@JsonKey() final  bool awaitingDecision;
@override final  IncomingOffer? incomingOffer;
@override final  AppFailure? failure;

/// Create a copy of TransferView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferViewCopyWith<_TransferView> get copyWith => __$TransferViewCopyWithImpl<_TransferView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferView&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.role, role) || other.role == role)&&(identical(other.overallProgress, overallProgress) || other.overallProgress == overallProgress)&&(identical(other.bytesDone, bytesDone) || other.bytesDone == bytesDone)&&(identical(other.bytesTotal, bytesTotal) || other.bytesTotal == bytesTotal)&&(identical(other.speedBytesPerSec, speedBytesPerSec) || other.speedBytesPerSec == speedBytesPerSec)&&(identical(other.etaSeconds, etaSeconds) || other.etaSeconds == etaSeconds)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.currentFileName, currentFileName) || other.currentFileName == currentFileName)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.awaitingDecision, awaitingDecision) || other.awaitingDecision == awaitingDecision)&&(identical(other.incomingOffer, incomingOffer) || other.incomingOffer == incomingOffer)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,phase,role,overallProgress,bytesDone,bytesTotal,speedBytesPerSec,etaSeconds,currentIndex,currentFileName,fileCount,const DeepCollectionEquality().hash(_items),elapsed,awaitingDecision,incomingOffer,failure);

@override
String toString() {
  return 'TransferView(phase: $phase, role: $role, overallProgress: $overallProgress, bytesDone: $bytesDone, bytesTotal: $bytesTotal, speedBytesPerSec: $speedBytesPerSec, etaSeconds: $etaSeconds, currentIndex: $currentIndex, currentFileName: $currentFileName, fileCount: $fileCount, items: $items, elapsed: $elapsed, awaitingDecision: $awaitingDecision, incomingOffer: $incomingOffer, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$TransferViewCopyWith<$Res> implements $TransferViewCopyWith<$Res> {
  factory _$TransferViewCopyWith(_TransferView value, $Res Function(_TransferView) _then) = __$TransferViewCopyWithImpl;
@override @useResult
$Res call({
 TransferPhase phase, TransferRole role, double overallProgress, int bytesDone, int bytesTotal, double speedBytesPerSec, int? etaSeconds, int? currentIndex, String? currentFileName, int fileCount, List<FileTransferItem> items, Duration elapsed, bool awaitingDecision, IncomingOffer? incomingOffer, AppFailure? failure
});


@override $IncomingOfferCopyWith<$Res>? get incomingOffer;@override $AppFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$TransferViewCopyWithImpl<$Res>
    implements _$TransferViewCopyWith<$Res> {
  __$TransferViewCopyWithImpl(this._self, this._then);

  final _TransferView _self;
  final $Res Function(_TransferView) _then;

/// Create a copy of TransferView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? role = null,Object? overallProgress = null,Object? bytesDone = null,Object? bytesTotal = null,Object? speedBytesPerSec = null,Object? etaSeconds = freezed,Object? currentIndex = freezed,Object? currentFileName = freezed,Object? fileCount = null,Object? items = null,Object? elapsed = null,Object? awaitingDecision = null,Object? incomingOffer = freezed,Object? failure = freezed,}) {
  return _then(_TransferView(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as TransferPhase,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TransferRole,overallProgress: null == overallProgress ? _self.overallProgress : overallProgress // ignore: cast_nullable_to_non_nullable
as double,bytesDone: null == bytesDone ? _self.bytesDone : bytesDone // ignore: cast_nullable_to_non_nullable
as int,bytesTotal: null == bytesTotal ? _self.bytesTotal : bytesTotal // ignore: cast_nullable_to_non_nullable
as int,speedBytesPerSec: null == speedBytesPerSec ? _self.speedBytesPerSec : speedBytesPerSec // ignore: cast_nullable_to_non_nullable
as double,etaSeconds: freezed == etaSeconds ? _self.etaSeconds : etaSeconds // ignore: cast_nullable_to_non_nullable
as int?,currentIndex: freezed == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int?,currentFileName: freezed == currentFileName ? _self.currentFileName : currentFileName // ignore: cast_nullable_to_non_nullable
as String?,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<FileTransferItem>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,awaitingDecision: null == awaitingDecision ? _self.awaitingDecision : awaitingDecision // ignore: cast_nullable_to_non_nullable
as bool,incomingOffer: freezed == incomingOffer ? _self.incomingOffer : incomingOffer // ignore: cast_nullable_to_non_nullable
as IncomingOffer?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

/// Create a copy of TransferView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncomingOfferCopyWith<$Res>? get incomingOffer {
    if (_self.incomingOffer == null) {
    return null;
  }

  return $IncomingOfferCopyWith<$Res>(_self.incomingOffer!, (value) {
    return _then(_self.copyWith(incomingOffer: value));
  });
}/// Create a copy of TransferView
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
