// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incoming_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IncomingOffer {

 String get senderLabel; int get fileCount; int get totalBytes; List<String> get typeSummary;
/// Create a copy of IncomingOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomingOfferCopyWith<IncomingOffer> get copyWith => _$IncomingOfferCopyWithImpl<IncomingOffer>(this as IncomingOffer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomingOffer&&(identical(other.senderLabel, senderLabel) || other.senderLabel == senderLabel)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&const DeepCollectionEquality().equals(other.typeSummary, typeSummary));
}


@override
int get hashCode => Object.hash(runtimeType,senderLabel,fileCount,totalBytes,const DeepCollectionEquality().hash(typeSummary));

@override
String toString() {
  return 'IncomingOffer(senderLabel: $senderLabel, fileCount: $fileCount, totalBytes: $totalBytes, typeSummary: $typeSummary)';
}


}

/// @nodoc
abstract mixin class $IncomingOfferCopyWith<$Res>  {
  factory $IncomingOfferCopyWith(IncomingOffer value, $Res Function(IncomingOffer) _then) = _$IncomingOfferCopyWithImpl;
@useResult
$Res call({
 String senderLabel, int fileCount, int totalBytes, List<String> typeSummary
});




}
/// @nodoc
class _$IncomingOfferCopyWithImpl<$Res>
    implements $IncomingOfferCopyWith<$Res> {
  _$IncomingOfferCopyWithImpl(this._self, this._then);

  final IncomingOffer _self;
  final $Res Function(IncomingOffer) _then;

/// Create a copy of IncomingOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? senderLabel = null,Object? fileCount = null,Object? totalBytes = null,Object? typeSummary = null,}) {
  return _then(_self.copyWith(
senderLabel: null == senderLabel ? _self.senderLabel : senderLabel // ignore: cast_nullable_to_non_nullable
as String,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,typeSummary: null == typeSummary ? _self.typeSummary : typeSummary // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [IncomingOffer].
extension IncomingOfferPatterns on IncomingOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncomingOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncomingOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncomingOffer value)  $default,){
final _that = this;
switch (_that) {
case _IncomingOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncomingOffer value)?  $default,){
final _that = this;
switch (_that) {
case _IncomingOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String senderLabel,  int fileCount,  int totalBytes,  List<String> typeSummary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncomingOffer() when $default != null:
return $default(_that.senderLabel,_that.fileCount,_that.totalBytes,_that.typeSummary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String senderLabel,  int fileCount,  int totalBytes,  List<String> typeSummary)  $default,) {final _that = this;
switch (_that) {
case _IncomingOffer():
return $default(_that.senderLabel,_that.fileCount,_that.totalBytes,_that.typeSummary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String senderLabel,  int fileCount,  int totalBytes,  List<String> typeSummary)?  $default,) {final _that = this;
switch (_that) {
case _IncomingOffer() when $default != null:
return $default(_that.senderLabel,_that.fileCount,_that.totalBytes,_that.typeSummary);case _:
  return null;

}
}

}

/// @nodoc


class _IncomingOffer implements IncomingOffer {
  const _IncomingOffer({required this.senderLabel, required this.fileCount, required this.totalBytes, required final  List<String> typeSummary}): _typeSummary = typeSummary;
  

@override final  String senderLabel;
@override final  int fileCount;
@override final  int totalBytes;
 final  List<String> _typeSummary;
@override List<String> get typeSummary {
  if (_typeSummary is EqualUnmodifiableListView) return _typeSummary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_typeSummary);
}


/// Create a copy of IncomingOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncomingOfferCopyWith<_IncomingOffer> get copyWith => __$IncomingOfferCopyWithImpl<_IncomingOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncomingOffer&&(identical(other.senderLabel, senderLabel) || other.senderLabel == senderLabel)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&const DeepCollectionEquality().equals(other._typeSummary, _typeSummary));
}


@override
int get hashCode => Object.hash(runtimeType,senderLabel,fileCount,totalBytes,const DeepCollectionEquality().hash(_typeSummary));

@override
String toString() {
  return 'IncomingOffer(senderLabel: $senderLabel, fileCount: $fileCount, totalBytes: $totalBytes, typeSummary: $typeSummary)';
}


}

/// @nodoc
abstract mixin class _$IncomingOfferCopyWith<$Res> implements $IncomingOfferCopyWith<$Res> {
  factory _$IncomingOfferCopyWith(_IncomingOffer value, $Res Function(_IncomingOffer) _then) = __$IncomingOfferCopyWithImpl;
@override @useResult
$Res call({
 String senderLabel, int fileCount, int totalBytes, List<String> typeSummary
});




}
/// @nodoc
class __$IncomingOfferCopyWithImpl<$Res>
    implements _$IncomingOfferCopyWith<$Res> {
  __$IncomingOfferCopyWithImpl(this._self, this._then);

  final _IncomingOffer _self;
  final $Res Function(_IncomingOffer) _then;

/// Create a copy of IncomingOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? senderLabel = null,Object? fileCount = null,Object? totalBytes = null,Object? typeSummary = null,}) {
  return _then(_IncomingOffer(
senderLabel: null == senderLabel ? _self.senderLabel : senderLabel // ignore: cast_nullable_to_non_nullable
as String,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,typeSummary: null == typeSummary ? _self._typeSummary : typeSummary // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
