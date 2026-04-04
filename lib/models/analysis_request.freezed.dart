// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AnalysisRequest _$AnalysisRequestFromJson(Map<String, dynamic> json) {
  return _AnalysisRequest.fromJson(json);
}

/// @nodoc
mixin _$AnalysisRequest {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;
  DateTime? get createdAt =>
      throw _privateConstructorUsedError; // Campos preenchidos pelo admin ao finalizar
  String? get speciesName => throw _privateConstructorUsedError;
  String? get careInstructions => throw _privateConstructorUsedError;
  String? get adminNotes => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;

  /// Serializes this AnalysisRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalysisRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalysisRequestCopyWith<AnalysisRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalysisRequestCopyWith<$Res> {
  factory $AnalysisRequestCopyWith(
      AnalysisRequest value,
      $Res Function(AnalysisRequest) then,
      ) = _$AnalysisRequestCopyWithImpl<$Res, AnalysisRequest>;
  @useResult
  $Res call({
    String id,
    String name,
    String notes,
    String userId,
    double latitude,
    double longitude,
    String status,
    List<String> imageUrls,
    DateTime? createdAt,
    String? speciesName,
    String? careInstructions,
    String? adminNotes,
    DateTime? reviewedAt,
  });
}

/// @nodoc
class _$AnalysisRequestCopyWithImpl<$Res, $Val extends AnalysisRequest>
    implements $AnalysisRequestCopyWith<$Res> {
  _$AnalysisRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalysisRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? notes = null,
    Object? userId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? status = null,
    Object? imageUrls = null,
    Object? createdAt = freezed,
    Object? speciesName = freezed,
    Object? careInstructions = freezed,
    Object? adminNotes = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
        as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
        as String,
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
        as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
        as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
        as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
        as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
        as String,
        imageUrls: null == imageUrls
            ? _value.imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
        as List<String>,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
        as DateTime?,
        speciesName: freezed == speciesName
            ? _value.speciesName
            : speciesName // ignore: cast_nullable_to_non_nullable
        as String?,
        careInstructions: freezed == careInstructions
            ? _value.careInstructions
            : careInstructions // ignore: cast_nullable_to_non_nullable
        as String?,
        adminNotes: freezed == adminNotes
            ? _value.adminNotes
            : adminNotes // ignore: cast_nullable_to_non_nullable
        as String?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
        as DateTime?,
      )
      as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnalysisRequestImplCopyWith<$Res>
    implements $AnalysisRequestCopyWith<$Res> {
  factory _$$AnalysisRequestImplCopyWith(
      _$AnalysisRequestImpl value,
      $Res Function(_$AnalysisRequestImpl) then,
      ) = __$$AnalysisRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String notes,
    String userId,
    double latitude,
    double longitude,
    String status,
    List<String> imageUrls,
    DateTime? createdAt,
    String? speciesName,
    String? careInstructions,
    String? adminNotes,
    DateTime? reviewedAt,
  });
}

/// @nodoc
class __$$AnalysisRequestImplCopyWithImpl<$Res>
    extends _$AnalysisRequestCopyWithImpl<$Res, _$AnalysisRequestImpl>
    implements _$$AnalysisRequestImplCopyWith<$Res> {
  __$$AnalysisRequestImplCopyWithImpl(
      _$AnalysisRequestImpl _value,
      $Res Function(_$AnalysisRequestImpl) _then,
      ) : super(_value, _then);

  /// Create a copy of AnalysisRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? notes = null,
    Object? userId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? status = null,
    Object? imageUrls = null,
    Object? createdAt = freezed,
    Object? speciesName = freezed,
    Object? careInstructions = freezed,
    Object? adminNotes = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(
      _$AnalysisRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
        as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
        as String,
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
        as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
        as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
        as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
        as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
        as String,
        imageUrls: null == imageUrls
            ? _value._imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
        as List<String>,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
        as DateTime?,
        speciesName: freezed == speciesName
            ? _value.speciesName
            : speciesName // ignore: cast_nullable_to_non_nullable
        as String?,
        careInstructions: freezed == careInstructions
            ? _value.careInstructions
            : careInstructions // ignore: cast_nullable_to_non_nullable
        as String?,
        adminNotes: freezed == adminNotes
            ? _value.adminNotes
            : adminNotes // ignore: cast_nullable_to_non_nullable
        as String?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
        as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisRequestImpl implements _AnalysisRequest {
  const _$AnalysisRequestImpl({
    required this.id,
    required this.name,
    required this.notes,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    final List<String> imageUrls = const [],
    this.createdAt,
    this.speciesName,
    this.careInstructions,
    this.adminNotes,
    this.reviewedAt,
  }) : _imageUrls = imageUrls;

  factory _$AnalysisRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String notes;
  @override
  final String userId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String status;
  final List<String> _imageUrls;
  @override
  @JsonKey()
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  final DateTime? createdAt;
  // Campos preenchidos pelo admin ao finalizar
  @override
  final String? speciesName;
  @override
  final String? careInstructions;
  @override
  final String? adminNotes;
  @override
  final DateTime? reviewedAt;

  @override
  String toString() {
    return 'AnalysisRequest(id: $id, name: $name, notes: $notes, userId: $userId, latitude: $latitude, longitude: $longitude, status: $status, imageUrls: $imageUrls, createdAt: $createdAt, speciesName: $speciesName, careInstructions: $careInstructions, adminNotes: $adminNotes, reviewedAt: $reviewedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._imageUrls,
              _imageUrls,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.speciesName, speciesName) ||
                other.speciesName == speciesName) &&
            (identical(other.careInstructions, careInstructions) ||
                other.careInstructions == careInstructions) &&
            (identical(other.adminNotes, adminNotes) ||
                other.adminNotes == adminNotes) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    notes,
    userId,
    latitude,
    longitude,
    status,
    const DeepCollectionEquality().hash(_imageUrls),
    createdAt,
    speciesName,
    careInstructions,
    adminNotes,
    reviewedAt,
  );

  /// Create a copy of AnalysisRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisRequestImplCopyWith<_$AnalysisRequestImpl> get copyWith =>
      __$$AnalysisRequestImplCopyWithImpl<_$AnalysisRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalysisRequestImplToJson(this);
  }
}

abstract class _AnalysisRequest implements AnalysisRequest {
  const factory _AnalysisRequest({
    required final String id,
    required final String name,
    required final String notes,
    required final String userId,
    required final double latitude,
    required final double longitude,
    required final String status,
    final List<String> imageUrls,
    final DateTime? createdAt,
    final String? speciesName,
    final String? careInstructions,
    final String? adminNotes,
    final DateTime? reviewedAt,
  }) = _$AnalysisRequestImpl;

  factory _AnalysisRequest.fromJson(Map<String, dynamic> json) =
  _$AnalysisRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get notes;
  @override
  String get userId;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get status;
  @override
  List<String> get imageUrls;
  @override
  DateTime? get createdAt; // Campos preenchidos pelo admin ao finalizar
  @override
  String? get speciesName;
  @override
  String? get careInstructions;
  @override
  String? get adminNotes;
  @override
  DateTime? get reviewedAt;

  /// Create a copy of AnalysisRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisRequestImplCopyWith<_$AnalysisRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
