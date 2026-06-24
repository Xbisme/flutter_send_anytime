// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signaling_channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignalingMessage {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignalingMessage()';
}


}

/// @nodoc
class $SignalingMessageCopyWith<$Res>  {
$SignalingMessageCopyWith(SignalingMessage _, $Res Function(SignalingMessage) __);
}


/// Adds pattern-matching-related methods to [SignalingMessage].
extension SignalingMessagePatterns on SignalingMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SignalingOffer value)?  offer,TResult Function( SignalingAnswer value)?  answer,TResult Function( SignalingIceCandidate value)?  iceCandidate,TResult Function( SignalingBye value)?  bye,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SignalingOffer() when offer != null:
return offer(_that);case SignalingAnswer() when answer != null:
return answer(_that);case SignalingIceCandidate() when iceCandidate != null:
return iceCandidate(_that);case SignalingBye() when bye != null:
return bye(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SignalingOffer value)  offer,required TResult Function( SignalingAnswer value)  answer,required TResult Function( SignalingIceCandidate value)  iceCandidate,required TResult Function( SignalingBye value)  bye,}){
final _that = this;
switch (_that) {
case SignalingOffer():
return offer(_that);case SignalingAnswer():
return answer(_that);case SignalingIceCandidate():
return iceCandidate(_that);case SignalingBye():
return bye(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SignalingOffer value)?  offer,TResult? Function( SignalingAnswer value)?  answer,TResult? Function( SignalingIceCandidate value)?  iceCandidate,TResult? Function( SignalingBye value)?  bye,}){
final _that = this;
switch (_that) {
case SignalingOffer() when offer != null:
return offer(_that);case SignalingAnswer() when answer != null:
return answer(_that);case SignalingIceCandidate() when iceCandidate != null:
return iceCandidate(_that);case SignalingBye() when bye != null:
return bye(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String sdp)?  offer,TResult Function( String sdp)?  answer,TResult Function( String candidate,  String? sdpMid,  int? sdpMLineIndex)?  iceCandidate,TResult Function()?  bye,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SignalingOffer() when offer != null:
return offer(_that.sdp);case SignalingAnswer() when answer != null:
return answer(_that.sdp);case SignalingIceCandidate() when iceCandidate != null:
return iceCandidate(_that.candidate,_that.sdpMid,_that.sdpMLineIndex);case SignalingBye() when bye != null:
return bye();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String sdp)  offer,required TResult Function( String sdp)  answer,required TResult Function( String candidate,  String? sdpMid,  int? sdpMLineIndex)  iceCandidate,required TResult Function()  bye,}) {final _that = this;
switch (_that) {
case SignalingOffer():
return offer(_that.sdp);case SignalingAnswer():
return answer(_that.sdp);case SignalingIceCandidate():
return iceCandidate(_that.candidate,_that.sdpMid,_that.sdpMLineIndex);case SignalingBye():
return bye();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String sdp)?  offer,TResult? Function( String sdp)?  answer,TResult? Function( String candidate,  String? sdpMid,  int? sdpMLineIndex)?  iceCandidate,TResult? Function()?  bye,}) {final _that = this;
switch (_that) {
case SignalingOffer() when offer != null:
return offer(_that.sdp);case SignalingAnswer() when answer != null:
return answer(_that.sdp);case SignalingIceCandidate() when iceCandidate != null:
return iceCandidate(_that.candidate,_that.sdpMid,_that.sdpMLineIndex);case SignalingBye() when bye != null:
return bye();case _:
  return null;

}
}

}

/// @nodoc


class SignalingOffer implements SignalingMessage {
  const SignalingOffer({required this.sdp});
  

 final  String sdp;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingOfferCopyWith<SignalingOffer> get copyWith => _$SignalingOfferCopyWithImpl<SignalingOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingOffer&&(identical(other.sdp, sdp) || other.sdp == sdp));
}


@override
int get hashCode => Object.hash(runtimeType,sdp);

@override
String toString() {
  return 'SignalingMessage.offer(sdp: $sdp)';
}


}

/// @nodoc
abstract mixin class $SignalingOfferCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingOfferCopyWith(SignalingOffer value, $Res Function(SignalingOffer) _then) = _$SignalingOfferCopyWithImpl;
@useResult
$Res call({
 String sdp
});




}
/// @nodoc
class _$SignalingOfferCopyWithImpl<$Res>
    implements $SignalingOfferCopyWith<$Res> {
  _$SignalingOfferCopyWithImpl(this._self, this._then);

  final SignalingOffer _self;
  final $Res Function(SignalingOffer) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sdp = null,}) {
  return _then(SignalingOffer(
sdp: null == sdp ? _self.sdp : sdp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SignalingAnswer implements SignalingMessage {
  const SignalingAnswer({required this.sdp});
  

 final  String sdp;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingAnswerCopyWith<SignalingAnswer> get copyWith => _$SignalingAnswerCopyWithImpl<SignalingAnswer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingAnswer&&(identical(other.sdp, sdp) || other.sdp == sdp));
}


@override
int get hashCode => Object.hash(runtimeType,sdp);

@override
String toString() {
  return 'SignalingMessage.answer(sdp: $sdp)';
}


}

/// @nodoc
abstract mixin class $SignalingAnswerCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingAnswerCopyWith(SignalingAnswer value, $Res Function(SignalingAnswer) _then) = _$SignalingAnswerCopyWithImpl;
@useResult
$Res call({
 String sdp
});




}
/// @nodoc
class _$SignalingAnswerCopyWithImpl<$Res>
    implements $SignalingAnswerCopyWith<$Res> {
  _$SignalingAnswerCopyWithImpl(this._self, this._then);

  final SignalingAnswer _self;
  final $Res Function(SignalingAnswer) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sdp = null,}) {
  return _then(SignalingAnswer(
sdp: null == sdp ? _self.sdp : sdp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SignalingIceCandidate implements SignalingMessage {
  const SignalingIceCandidate({required this.candidate, this.sdpMid, this.sdpMLineIndex});
  

 final  String candidate;
 final  String? sdpMid;
 final  int? sdpMLineIndex;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingIceCandidateCopyWith<SignalingIceCandidate> get copyWith => _$SignalingIceCandidateCopyWithImpl<SignalingIceCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingIceCandidate&&(identical(other.candidate, candidate) || other.candidate == candidate)&&(identical(other.sdpMid, sdpMid) || other.sdpMid == sdpMid)&&(identical(other.sdpMLineIndex, sdpMLineIndex) || other.sdpMLineIndex == sdpMLineIndex));
}


@override
int get hashCode => Object.hash(runtimeType,candidate,sdpMid,sdpMLineIndex);

@override
String toString() {
  return 'SignalingMessage.iceCandidate(candidate: $candidate, sdpMid: $sdpMid, sdpMLineIndex: $sdpMLineIndex)';
}


}

/// @nodoc
abstract mixin class $SignalingIceCandidateCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingIceCandidateCopyWith(SignalingIceCandidate value, $Res Function(SignalingIceCandidate) _then) = _$SignalingIceCandidateCopyWithImpl;
@useResult
$Res call({
 String candidate, String? sdpMid, int? sdpMLineIndex
});




}
/// @nodoc
class _$SignalingIceCandidateCopyWithImpl<$Res>
    implements $SignalingIceCandidateCopyWith<$Res> {
  _$SignalingIceCandidateCopyWithImpl(this._self, this._then);

  final SignalingIceCandidate _self;
  final $Res Function(SignalingIceCandidate) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? candidate = null,Object? sdpMid = freezed,Object? sdpMLineIndex = freezed,}) {
  return _then(SignalingIceCandidate(
candidate: null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as String,sdpMid: freezed == sdpMid ? _self.sdpMid : sdpMid // ignore: cast_nullable_to_non_nullable
as String?,sdpMLineIndex: freezed == sdpMLineIndex ? _self.sdpMLineIndex : sdpMLineIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class SignalingBye implements SignalingMessage {
  const SignalingBye();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingBye);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignalingMessage.bye()';
}


}




// dart format on
