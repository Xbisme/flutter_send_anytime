// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nearby_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NearbyDevice {

 String get id; String get displayName; String get code; DateTime get lastSeen;
/// Create a copy of NearbyDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NearbyDeviceCopyWith<NearbyDevice> get copyWith => _$NearbyDeviceCopyWithImpl<NearbyDevice>(this as NearbyDevice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NearbyDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.code, code) || other.code == code)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,code,lastSeen);

@override
String toString() {
  return 'NearbyDevice(id: $id, displayName: $displayName, code: $code, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class $NearbyDeviceCopyWith<$Res>  {
  factory $NearbyDeviceCopyWith(NearbyDevice value, $Res Function(NearbyDevice) _then) = _$NearbyDeviceCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String code, DateTime lastSeen
});




}
/// @nodoc
class _$NearbyDeviceCopyWithImpl<$Res>
    implements $NearbyDeviceCopyWith<$Res> {
  _$NearbyDeviceCopyWithImpl(this._self, this._then);

  final NearbyDevice _self;
  final $Res Function(NearbyDevice) _then;

/// Create a copy of NearbyDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? code = null,Object? lastSeen = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [NearbyDevice].
extension NearbyDevicePatterns on NearbyDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NearbyDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NearbyDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NearbyDevice value)  $default,){
final _that = this;
switch (_that) {
case _NearbyDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NearbyDevice value)?  $default,){
final _that = this;
switch (_that) {
case _NearbyDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String code,  DateTime lastSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NearbyDevice() when $default != null:
return $default(_that.id,_that.displayName,_that.code,_that.lastSeen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String code,  DateTime lastSeen)  $default,) {final _that = this;
switch (_that) {
case _NearbyDevice():
return $default(_that.id,_that.displayName,_that.code,_that.lastSeen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String code,  DateTime lastSeen)?  $default,) {final _that = this;
switch (_that) {
case _NearbyDevice() when $default != null:
return $default(_that.id,_that.displayName,_that.code,_that.lastSeen);case _:
  return null;

}
}

}

/// @nodoc


class _NearbyDevice extends NearbyDevice {
  const _NearbyDevice({required this.id, required this.displayName, required this.code, required this.lastSeen}): super._();
  

@override final  String id;
@override final  String displayName;
@override final  String code;
@override final  DateTime lastSeen;

/// Create a copy of NearbyDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NearbyDeviceCopyWith<_NearbyDevice> get copyWith => __$NearbyDeviceCopyWithImpl<_NearbyDevice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NearbyDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.code, code) || other.code == code)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,code,lastSeen);

@override
String toString() {
  return 'NearbyDevice(id: $id, displayName: $displayName, code: $code, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class _$NearbyDeviceCopyWith<$Res> implements $NearbyDeviceCopyWith<$Res> {
  factory _$NearbyDeviceCopyWith(_NearbyDevice value, $Res Function(_NearbyDevice) _then) = __$NearbyDeviceCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String code, DateTime lastSeen
});




}
/// @nodoc
class __$NearbyDeviceCopyWithImpl<$Res>
    implements _$NearbyDeviceCopyWith<$Res> {
  __$NearbyDeviceCopyWithImpl(this._self, this._then);

  final _NearbyDevice _self;
  final $Res Function(_NearbyDevice) _then;

/// Create a copy of NearbyDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? code = null,Object? lastSeen = null,}) {
  return _then(_NearbyDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
