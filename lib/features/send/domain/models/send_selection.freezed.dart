// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'send_selection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SendSelection {

 List<FileSource> get files;
/// Create a copy of SendSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendSelectionCopyWith<SendSelection> get copyWith => _$SendSelectionCopyWithImpl<SendSelection>(this as SendSelection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendSelection&&const DeepCollectionEquality().equals(other.files, files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'SendSelection(files: $files)';
}


}

/// @nodoc
abstract mixin class $SendSelectionCopyWith<$Res>  {
  factory $SendSelectionCopyWith(SendSelection value, $Res Function(SendSelection) _then) = _$SendSelectionCopyWithImpl;
@useResult
$Res call({
 List<FileSource> files
});




}
/// @nodoc
class _$SendSelectionCopyWithImpl<$Res>
    implements $SendSelectionCopyWith<$Res> {
  _$SendSelectionCopyWithImpl(this._self, this._then);

  final SendSelection _self;
  final $Res Function(SendSelection) _then;

/// Create a copy of SendSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? files = null,}) {
  return _then(_self.copyWith(
files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<FileSource>,
  ));
}

}


/// Adds pattern-matching-related methods to [SendSelection].
extension SendSelectionPatterns on SendSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SendSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SendSelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SendSelection value)  $default,){
final _that = this;
switch (_that) {
case _SendSelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SendSelection value)?  $default,){
final _that = this;
switch (_that) {
case _SendSelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FileSource> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SendSelection() when $default != null:
return $default(_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FileSource> files)  $default,) {final _that = this;
switch (_that) {
case _SendSelection():
return $default(_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FileSource> files)?  $default,) {final _that = this;
switch (_that) {
case _SendSelection() when $default != null:
return $default(_that.files);case _:
  return null;

}
}

}

/// @nodoc


class _SendSelection extends SendSelection {
  const _SendSelection({final  List<FileSource> files = const <FileSource>[]}): _files = files,super._();
  

 final  List<FileSource> _files;
@override@JsonKey() List<FileSource> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of SendSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendSelectionCopyWith<_SendSelection> get copyWith => __$SendSelectionCopyWithImpl<_SendSelection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendSelection&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'SendSelection(files: $files)';
}


}

/// @nodoc
abstract mixin class _$SendSelectionCopyWith<$Res> implements $SendSelectionCopyWith<$Res> {
  factory _$SendSelectionCopyWith(_SendSelection value, $Res Function(_SendSelection) _then) = __$SendSelectionCopyWithImpl;
@override @useResult
$Res call({
 List<FileSource> files
});




}
/// @nodoc
class __$SendSelectionCopyWithImpl<$Res>
    implements _$SendSelectionCopyWith<$Res> {
  __$SendSelectionCopyWithImpl(this._self, this._then);

  final _SendSelection _self;
  final $Res Function(_SendSelection) _then;

/// Create a copy of SendSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? files = null,}) {
  return _then(_SendSelection(
files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<FileSource>,
  ));
}


}

// dart format on
