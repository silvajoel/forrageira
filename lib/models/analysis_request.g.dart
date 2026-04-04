// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnalysisRequestImpl _$$AnalysisRequestImplFromJson(
  Map<String, dynamic> json,
) => _$AnalysisRequestImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  notes: json['notes'] as String,
  userId: json['userId'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  status: json['status'] as String,
  imageUrls:
      (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  speciesName: json['speciesName'] as String?,
  careInstructions: json['careInstructions'] as String?,
  adminNotes: json['adminNotes'] as String?,
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
);

Map<String, dynamic> _$$AnalysisRequestImplToJson(
  _$AnalysisRequestImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'notes': instance.notes,
  'userId': instance.userId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'status': instance.status,
  'imageUrls': instance.imageUrls,
  'createdAt': instance.createdAt?.toIso8601String(),
  'speciesName': instance.speciesName,
  'careInstructions': instance.careInstructions,
  'adminNotes': instance.adminNotes,
  'reviewedAt': instance.reviewedAt?.toIso8601String(),
};
