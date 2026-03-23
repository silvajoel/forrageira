// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalysisRequest _$AnalysisRequestFromJson(Map<String, dynamic> json) =>
    _AnalysisRequest(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      userId: json['userId'] as String,
      latitude: json['latitude'] as num,
      longitude: json['longitude'] as num,
      images: (json['images'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      status: json['status'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AnalysisRequestToJson(_AnalysisRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'notes': instance.notes,
      'userId': instance.userId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'images': instance.images,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
