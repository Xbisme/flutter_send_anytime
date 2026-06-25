// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_scan_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QrScanView {

 CameraPermissionStatus get permission;/// Torch on/off (only meaningful when [permission] is granted).
 bool get torchOn;/// Latched true once a valid code is accepted, to enforce a single join
/// (FR-014).
 bool get handled;
/// Create a copy of QrScanView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrScanViewCopyWith<QrScanView> get copyWith => _$QrScanViewCopyWithImpl<QrScanView>(this as QrScanView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrScanView&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.torchOn, torchOn) || other.torchOn == torchOn)&&(identical(other.handled, handled) || other.handled == handled));
}


@override
int get hashCode => Object.hash(runtimeType,permission,torchOn,handled);

@override
String toString() {
  return 'QrScanView(permission: $permission, torchOn: $torchOn, handled: $handled)';
}


}

/// @nodoc
abstract mixin class $QrScanViewCopyWith<$Res>  {
  factory $QrScanViewCopyWith(QrScanView value, $Res Function(QrScanView) _then) = _$QrScanViewCopyWithImpl;
@useResult
$Res call({
 CameraPermissionStatus permission, bool torchOn, bool handled
});




}
/// @nodoc
class _$QrScanViewCopyWithImpl<$Res>
    implements $QrScanViewCopyWith<$Res> {
  _$QrScanViewCopyWithImpl(this._self, this._then);

  final QrScanView _self;
  final $Res Function(QrScanView) _then;

/// Create a copy of QrScanView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? permission = null,Object? torchOn = null,Object? handled = null,}) {
  return _then(_self.copyWith(
permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as CameraPermissionStatus,torchOn: null == torchOn ? _self.torchOn : torchOn // ignore: cast_nullable_to_non_nullable
as bool,handled: null == handled ? _self.handled : handled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QrScanView].
extension QrScanViewPatterns on QrScanView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QrScanView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QrScanView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QrScanView value)  $default,){
final _that = this;
switch (_that) {
case _QrScanView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QrScanView value)?  $default,){
final _that = this;
switch (_that) {
case _QrScanView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CameraPermissionStatus permission,  bool torchOn,  bool handled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QrScanView() when $default != null:
return $default(_that.permission,_that.torchOn,_that.handled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CameraPermissionStatus permission,  bool torchOn,  bool handled)  $default,) {final _that = this;
switch (_that) {
case _QrScanView():
return $default(_that.permission,_that.torchOn,_that.handled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CameraPermissionStatus permission,  bool torchOn,  bool handled)?  $default,) {final _that = this;
switch (_that) {
case _QrScanView() when $default != null:
return $default(_that.permission,_that.torchOn,_that.handled);case _:
  return null;

}
}

}

/// @nodoc


class _QrScanView implements QrScanView {
  const _QrScanView({required this.permission, this.torchOn = false, this.handled = false});
  

@override final  CameraPermissionStatus permission;
/// Torch on/off (only meaningful when [permission] is granted).
@override@JsonKey() final  bool torchOn;
/// Latched true once a valid code is accepted, to enforce a single join
/// (FR-014).
@override@JsonKey() final  bool handled;

/// Create a copy of QrScanView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QrScanViewCopyWith<_QrScanView> get copyWith => __$QrScanViewCopyWithImpl<_QrScanView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QrScanView&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.torchOn, torchOn) || other.torchOn == torchOn)&&(identical(other.handled, handled) || other.handled == handled));
}


@override
int get hashCode => Object.hash(runtimeType,permission,torchOn,handled);

@override
String toString() {
  return 'QrScanView(permission: $permission, torchOn: $torchOn, handled: $handled)';
}


}

/// @nodoc
abstract mixin class _$QrScanViewCopyWith<$Res> implements $QrScanViewCopyWith<$Res> {
  factory _$QrScanViewCopyWith(_QrScanView value, $Res Function(_QrScanView) _then) = __$QrScanViewCopyWithImpl;
@override @useResult
$Res call({
 CameraPermissionStatus permission, bool torchOn, bool handled
});




}
/// @nodoc
class __$QrScanViewCopyWithImpl<$Res>
    implements _$QrScanViewCopyWith<$Res> {
  __$QrScanViewCopyWithImpl(this._self, this._then);

  final _QrScanView _self;
  final $Res Function(_QrScanView) _then;

/// Create a copy of QrScanView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? permission = null,Object? torchOn = null,Object? handled = null,}) {
  return _then(_QrScanView(
permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as CameraPermissionStatus,torchOn: null == torchOn ? _self.torchOn : torchOn // ignore: cast_nullable_to_non_nullable
as bool,handled: null == handled ? _self.handled : handled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
