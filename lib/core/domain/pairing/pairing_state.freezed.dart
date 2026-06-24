// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pairing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PairingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PairingState()';
}


}

/// @nodoc
class $PairingStateCopyWith<$Res>  {
$PairingStateCopyWith(PairingState _, $Res Function(PairingState) __);
}


/// Adds pattern-matching-related methods to [PairingState].
extension PairingStatePatterns on PairingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PairingIdle value)?  idle,TResult Function( PairingConnecting value)?  connecting,TResult Function( PairingHosting value)?  hosting,TResult Function( PairingJoining value)?  joining,TResult Function( PairingPeerPresent value)?  peerPresent,TResult Function( PairingConnected value)?  connected,TResult Function( PairingFailed value)?  failed,TResult Function( PairingClosed value)?  closed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PairingIdle() when idle != null:
return idle(_that);case PairingConnecting() when connecting != null:
return connecting(_that);case PairingHosting() when hosting != null:
return hosting(_that);case PairingJoining() when joining != null:
return joining(_that);case PairingPeerPresent() when peerPresent != null:
return peerPresent(_that);case PairingConnected() when connected != null:
return connected(_that);case PairingFailed() when failed != null:
return failed(_that);case PairingClosed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PairingIdle value)  idle,required TResult Function( PairingConnecting value)  connecting,required TResult Function( PairingHosting value)  hosting,required TResult Function( PairingJoining value)  joining,required TResult Function( PairingPeerPresent value)  peerPresent,required TResult Function( PairingConnected value)  connected,required TResult Function( PairingFailed value)  failed,required TResult Function( PairingClosed value)  closed,}){
final _that = this;
switch (_that) {
case PairingIdle():
return idle(_that);case PairingConnecting():
return connecting(_that);case PairingHosting():
return hosting(_that);case PairingJoining():
return joining(_that);case PairingPeerPresent():
return peerPresent(_that);case PairingConnected():
return connected(_that);case PairingFailed():
return failed(_that);case PairingClosed():
return closed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PairingIdle value)?  idle,TResult? Function( PairingConnecting value)?  connecting,TResult? Function( PairingHosting value)?  hosting,TResult? Function( PairingJoining value)?  joining,TResult? Function( PairingPeerPresent value)?  peerPresent,TResult? Function( PairingConnected value)?  connected,TResult? Function( PairingFailed value)?  failed,TResult? Function( PairingClosed value)?  closed,}){
final _that = this;
switch (_that) {
case PairingIdle() when idle != null:
return idle(_that);case PairingConnecting() when connecting != null:
return connecting(_that);case PairingHosting() when hosting != null:
return hosting(_that);case PairingJoining() when joining != null:
return joining(_that);case PairingPeerPresent() when peerPresent != null:
return peerPresent(_that);case PairingConnected() when connected != null:
return connected(_that);case PairingFailed() when failed != null:
return failed(_that);case PairingClosed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  connecting,TResult Function( PairingCode code)?  hosting,TResult Function()?  joining,TResult Function()?  peerPresent,TResult Function()?  connected,TResult Function( AppFailure failure)?  failed,TResult Function()?  closed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PairingIdle() when idle != null:
return idle();case PairingConnecting() when connecting != null:
return connecting();case PairingHosting() when hosting != null:
return hosting(_that.code);case PairingJoining() when joining != null:
return joining();case PairingPeerPresent() when peerPresent != null:
return peerPresent();case PairingConnected() when connected != null:
return connected();case PairingFailed() when failed != null:
return failed(_that.failure);case PairingClosed() when closed != null:
return closed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  connecting,required TResult Function( PairingCode code)  hosting,required TResult Function()  joining,required TResult Function()  peerPresent,required TResult Function()  connected,required TResult Function( AppFailure failure)  failed,required TResult Function()  closed,}) {final _that = this;
switch (_that) {
case PairingIdle():
return idle();case PairingConnecting():
return connecting();case PairingHosting():
return hosting(_that.code);case PairingJoining():
return joining();case PairingPeerPresent():
return peerPresent();case PairingConnected():
return connected();case PairingFailed():
return failed(_that.failure);case PairingClosed():
return closed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  connecting,TResult? Function( PairingCode code)?  hosting,TResult? Function()?  joining,TResult? Function()?  peerPresent,TResult? Function()?  connected,TResult? Function( AppFailure failure)?  failed,TResult? Function()?  closed,}) {final _that = this;
switch (_that) {
case PairingIdle() when idle != null:
return idle();case PairingConnecting() when connecting != null:
return connecting();case PairingHosting() when hosting != null:
return hosting(_that.code);case PairingJoining() when joining != null:
return joining();case PairingPeerPresent() when peerPresent != null:
return peerPresent();case PairingConnected() when connected != null:
return connected();case PairingFailed() when failed != null:
return failed(_that.failure);case PairingClosed() when closed != null:
return closed();case _:
  return null;

}
}

}

/// @nodoc


class PairingIdle implements PairingState {
  const PairingIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PairingState.idle()';
}


}




/// @nodoc


class PairingConnecting implements PairingState {
  const PairingConnecting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingConnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PairingState.connecting()';
}


}




/// @nodoc


class PairingHosting implements PairingState {
  const PairingHosting(this.code);
  

 final  PairingCode code;

/// Create a copy of PairingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PairingHostingCopyWith<PairingHosting> get copyWith => _$PairingHostingCopyWithImpl<PairingHosting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingHosting&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'PairingState.hosting(code: $code)';
}


}

/// @nodoc
abstract mixin class $PairingHostingCopyWith<$Res> implements $PairingStateCopyWith<$Res> {
  factory $PairingHostingCopyWith(PairingHosting value, $Res Function(PairingHosting) _then) = _$PairingHostingCopyWithImpl;
@useResult
$Res call({
 PairingCode code
});


$PairingCodeCopyWith<$Res> get code;

}
/// @nodoc
class _$PairingHostingCopyWithImpl<$Res>
    implements $PairingHostingCopyWith<$Res> {
  _$PairingHostingCopyWithImpl(this._self, this._then);

  final PairingHosting _self;
  final $Res Function(PairingHosting) _then;

/// Create a copy of PairingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(PairingHosting(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as PairingCode,
  ));
}

/// Create a copy of PairingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PairingCodeCopyWith<$Res> get code {
  
  return $PairingCodeCopyWith<$Res>(_self.code, (value) {
    return _then(_self.copyWith(code: value));
  });
}
}

/// @nodoc


class PairingJoining implements PairingState {
  const PairingJoining();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingJoining);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PairingState.joining()';
}


}




/// @nodoc


class PairingPeerPresent implements PairingState {
  const PairingPeerPresent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingPeerPresent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PairingState.peerPresent()';
}


}




/// @nodoc


class PairingConnected implements PairingState {
  const PairingConnected();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingConnected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PairingState.connected()';
}


}




/// @nodoc


class PairingFailed implements PairingState {
  const PairingFailed(this.failure);
  

 final  AppFailure failure;

/// Create a copy of PairingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PairingFailedCopyWith<PairingFailed> get copyWith => _$PairingFailedCopyWithImpl<PairingFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PairingState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PairingFailedCopyWith<$Res> implements $PairingStateCopyWith<$Res> {
  factory $PairingFailedCopyWith(PairingFailed value, $Res Function(PairingFailed) _then) = _$PairingFailedCopyWithImpl;
@useResult
$Res call({
 AppFailure failure
});


$AppFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PairingFailedCopyWithImpl<$Res>
    implements $PairingFailedCopyWith<$Res> {
  _$PairingFailedCopyWithImpl(this._self, this._then);

  final PairingFailed _self;
  final $Res Function(PairingFailed) _then;

/// Create a copy of PairingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PairingFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,
  ));
}

/// Create a copy of PairingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res> get failure {
  
  return $AppFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class PairingClosed implements PairingState {
  const PairingClosed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PairingClosed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PairingState.closed()';
}


}




// dart format on
