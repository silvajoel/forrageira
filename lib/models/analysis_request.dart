import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_request.freezed.dart';
part 'analysis_request.g.dart';

@freezed
abstract class AnalysisRequest with _$AnalysisRequest {
  const factory AnalysisRequest({
    required String id,
    required String name,
    String? notes,
    required String userId,
    required num latitude,
    required num longitude,
    required List<String> images,
    required String status,
    DateTime? createdAt,
  }) = _AnalysisRequest;

  factory AnalysisRequest.fromJson(Map<String, dynamic> json) =>
      _$AnalysisRequestFromJson(json);
}