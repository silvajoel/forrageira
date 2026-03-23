// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalysisRequest {

 String get id; String get name; String? get notes; String get userId; num get latitude; num get longitude; List<String> get images; String get status; DateTime? get createdAt;
/// Create a copy of AnalysisRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisRequestCopyWith<AnalysisRequest> get copyWith => _$AnalysisRequestCopyWithImpl<AnalysisRequest>(this as AnalysisRequest, _$identity);

  /// Serializes this AnalysisRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,notes,userId,latitude,longitude,const DeepCollectionEquality().hash(images),status,createdAt);

@override
String toString() {
  return 'AnalysisRequest(id: $id, name: $name, notes: $notes, userId: $userId, latitude: $latitude, longitude: $longitude, images: $images, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AnalysisRequestCopyWith<$Res>  {
  factory $AnalysisRequestCopyWith(AnalysisRequest value, $Res Function(AnalysisRequest) _then) = _$AnalysisRequestCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? notes, String userId, num latitude, num longitude, List<String> images, String status, DateTime? createdAt
});




}
/// @nodoc
class _$AnalysisRequestCopyWithImpl<$Res>
    implements $AnalysisRequestCopyWith<$Res> {
  _$AnalysisRequestCopyWithImpl(this._self, this._then);

  final AnalysisRequest _self;
  final $Res Function(AnalysisRequest) _then;

/// Create a copy of AnalysisRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? notes = freezed,Object? userId = null,Object? latitude = null,Object? longitude = null,Object? images = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as num,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as num,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalysisRequest].
extension AnalysisRequestPatterns on AnalysisRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisRequest value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? notes,  String userId,  num latitude,  num longitude,  List<String> images,  String status,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisRequest() when $default != null:
return $default(_that.id,_that.name,_that.notes,_that.userId,_that.latitude,_that.longitude,_that.images,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? notes,  String userId,  num latitude,  num longitude,  List<String> images,  String status,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AnalysisRequest():
return $default(_that.id,_that.name,_that.notes,_that.userId,_that.latitude,_that.longitude,_that.images,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? notes,  String userId,  num latitude,  num longitude,  List<String> images,  String status,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisRequest() when $default != null:
return $default(_that.id,_that.name,_that.notes,_that.userId,_that.latitude,_that.longitude,_that.images,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalysisRequest implements AnalysisRequest {
  const _AnalysisRequest({required this.id, required this.name, this.notes, required this.userId, required this.latitude, required this.longitude, required final  List<String> images, required this.status, this.createdAt}): _images = images;
  factory _AnalysisRequest.fromJson(Map<String, dynamic> json) => _$AnalysisRequestFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? notes;
@override final  String userId;
@override final  num latitude;
@override final  num longitude;
 final  List<String> _images;
@override List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  String status;
@override final  DateTime? createdAt;

/// Create a copy of AnalysisRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisRequestCopyWith<_AnalysisRequest> get copyWith => __$AnalysisRequestCopyWithImpl<_AnalysisRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalysisRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,notes,userId,latitude,longitude,const DeepCollectionEquality().hash(_images),status,createdAt);

@override
String toString() {
  return 'AnalysisRequest(id: $id, name: $name, notes: $notes, userId: $userId, latitude: $latitude, longitude: $longitude, images: $images, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AnalysisRequestCopyWith<$Res> implements $AnalysisRequestCopyWith<$Res> {
  factory _$AnalysisRequestCopyWith(_AnalysisRequest value, $Res Function(_AnalysisRequest) _then) = __$AnalysisRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? notes, String userId, num latitude, num longitude, List<String> images, String status, DateTime? createdAt
});




}
/// @nodoc
class __$AnalysisRequestCopyWithImpl<$Res>
    implements _$AnalysisRequestCopyWith<$Res> {
  __$AnalysisRequestCopyWithImpl(this._self, this._then);

  final _AnalysisRequest _self;
  final $Res Function(_AnalysisRequest) _then;

/// Create a copy of AnalysisRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? notes = freezed,Object? userId = null,Object? latitude = null,Object? longitude = null,Object? images = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_AnalysisRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as num,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as num,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
