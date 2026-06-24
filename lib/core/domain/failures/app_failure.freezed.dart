// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure()';
}


}

/// @nodoc
class $AppFailureCopyWith<$Res>  {
$AppFailureCopyWith(AppFailure _, $Res Function(AppFailure) __);
}


/// Adds pattern-matching-related methods to [AppFailure].
extension AppFailurePatterns on AppFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AppFailureUnexpected value)?  unexpected,TResult Function( AppFailureNotImplemented value)?  notImplemented,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AppFailureUnexpected() when unexpected != null:
return unexpected(_that);case AppFailureNotImplemented() when notImplemented != null:
return notImplemented(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AppFailureUnexpected value)  unexpected,required TResult Function( AppFailureNotImplemented value)  notImplemented,}){
final _that = this;
switch (_that) {
case AppFailureUnexpected():
return unexpected(_that);case AppFailureNotImplemented():
return notImplemented(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AppFailureUnexpected value)?  unexpected,TResult? Function( AppFailureNotImplemented value)?  notImplemented,}){
final _that = this;
switch (_that) {
case AppFailureUnexpected() when unexpected != null:
return unexpected(_that);case AppFailureNotImplemented() when notImplemented != null:
return notImplemented(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? message,  Object? error)?  unexpected,TResult Function()?  notImplemented,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AppFailureUnexpected() when unexpected != null:
return unexpected(_that.message,_that.error);case AppFailureNotImplemented() when notImplemented != null:
return notImplemented();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? message,  Object? error)  unexpected,required TResult Function()  notImplemented,}) {final _that = this;
switch (_that) {
case AppFailureUnexpected():
return unexpected(_that.message,_that.error);case AppFailureNotImplemented():
return notImplemented();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? message,  Object? error)?  unexpected,TResult? Function()?  notImplemented,}) {final _that = this;
switch (_that) {
case AppFailureUnexpected() when unexpected != null:
return unexpected(_that.message,_that.error);case AppFailureNotImplemented() when notImplemented != null:
return notImplemented();case _:
  return null;

}
}

}

/// @nodoc


class AppFailureUnexpected implements AppFailure {
  const AppFailureUnexpected({this.message, this.error});
  

 final  String? message;
 final  Object? error;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppFailureUnexpectedCopyWith<AppFailureUnexpected> get copyWith => _$AppFailureUnexpectedCopyWithImpl<AppFailureUnexpected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailureUnexpected&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'AppFailure.unexpected(message: $message, error: $error)';
}


}

/// @nodoc
abstract mixin class $AppFailureUnexpectedCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $AppFailureUnexpectedCopyWith(AppFailureUnexpected value, $Res Function(AppFailureUnexpected) _then) = _$AppFailureUnexpectedCopyWithImpl;
@useResult
$Res call({
 String? message, Object? error
});




}
/// @nodoc
class _$AppFailureUnexpectedCopyWithImpl<$Res>
    implements $AppFailureUnexpectedCopyWith<$Res> {
  _$AppFailureUnexpectedCopyWithImpl(this._self, this._then);

  final AppFailureUnexpected _self;
  final $Res Function(AppFailureUnexpected) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? error = freezed,}) {
  return _then(AppFailureUnexpected(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error ,
  ));
}


}

/// @nodoc


class AppFailureNotImplemented implements AppFailure {
  const AppFailureNotImplemented();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailureNotImplemented);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.notImplemented()';
}


}




// dart format on
