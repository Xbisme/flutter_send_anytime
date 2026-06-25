// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryFilter {

 TransferDirection? get direction; DateTime? get from; DateTime? get to; String? get query;
/// Create a copy of HistoryFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryFilterCopyWith<HistoryFilter> get copyWith => _$HistoryFilterCopyWithImpl<HistoryFilter>(this as HistoryFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryFilter&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,direction,from,to,query);

@override
String toString() {
  return 'HistoryFilter(direction: $direction, from: $from, to: $to, query: $query)';
}


}

/// @nodoc
abstract mixin class $HistoryFilterCopyWith<$Res>  {
  factory $HistoryFilterCopyWith(HistoryFilter value, $Res Function(HistoryFilter) _then) = _$HistoryFilterCopyWithImpl;
@useResult
$Res call({
 TransferDirection? direction, DateTime? from, DateTime? to, String? query
});




}
/// @nodoc
class _$HistoryFilterCopyWithImpl<$Res>
    implements $HistoryFilterCopyWith<$Res> {
  _$HistoryFilterCopyWithImpl(this._self, this._then);

  final HistoryFilter _self;
  final $Res Function(HistoryFilter) _then;

/// Create a copy of HistoryFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = freezed,Object? from = freezed,Object? to = freezed,Object? query = freezed,}) {
  return _then(_self.copyWith(
direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TransferDirection?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryFilter].
extension HistoryFilterPatterns on HistoryFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryFilter value)  $default,){
final _that = this;
switch (_that) {
case _HistoryFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryFilter value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransferDirection? direction,  DateTime? from,  DateTime? to,  String? query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryFilter() when $default != null:
return $default(_that.direction,_that.from,_that.to,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransferDirection? direction,  DateTime? from,  DateTime? to,  String? query)  $default,) {final _that = this;
switch (_that) {
case _HistoryFilter():
return $default(_that.direction,_that.from,_that.to,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransferDirection? direction,  DateTime? from,  DateTime? to,  String? query)?  $default,) {final _that = this;
switch (_that) {
case _HistoryFilter() when $default != null:
return $default(_that.direction,_that.from,_that.to,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryFilter extends HistoryFilter {
  const _HistoryFilter({this.direction, this.from, this.to, this.query}): super._();
  

@override final  TransferDirection? direction;
@override final  DateTime? from;
@override final  DateTime? to;
@override final  String? query;

/// Create a copy of HistoryFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryFilterCopyWith<_HistoryFilter> get copyWith => __$HistoryFilterCopyWithImpl<_HistoryFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryFilter&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,direction,from,to,query);

@override
String toString() {
  return 'HistoryFilter(direction: $direction, from: $from, to: $to, query: $query)';
}


}

/// @nodoc
abstract mixin class _$HistoryFilterCopyWith<$Res> implements $HistoryFilterCopyWith<$Res> {
  factory _$HistoryFilterCopyWith(_HistoryFilter value, $Res Function(_HistoryFilter) _then) = __$HistoryFilterCopyWithImpl;
@override @useResult
$Res call({
 TransferDirection? direction, DateTime? from, DateTime? to, String? query
});




}
/// @nodoc
class __$HistoryFilterCopyWithImpl<$Res>
    implements _$HistoryFilterCopyWith<$Res> {
  __$HistoryFilterCopyWithImpl(this._self, this._then);

  final _HistoryFilter _self;
  final $Res Function(_HistoryFilter) _then;

/// Create a copy of HistoryFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = freezed,Object? from = freezed,Object? to = freezed,Object? query = freezed,}) {
  return _then(_HistoryFilter(
direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TransferDirection?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
