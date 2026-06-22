
import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/image_url_resolver.dart';

part 'analysis_request.freezed.dart';
part 'analysis_request.g.dart';

@freezed
abstract class AnalysisRequest with _$AnalysisRequest {
  const factory AnalysisRequest({
    required String id,
    required String name,
    required String notes,
    required String userId,
    required double latitude,
    required double longitude,
    required String status,
    @Default([]) List<String> imageUrls,
    DateTime? createdAt,
    // Campos preenchidos pelo admin ao finalizar
    String? speciesName,
    String? careInstructions,
    String? adminNotes,
    DateTime? reviewedAt,
  }) = _AnalysisRequest;

  factory AnalysisRequest.fromJson(Map<String, dynamic> json) =>
      _$AnalysisRequestFromJson(json);
}

extension AnalysisRequestApi on AnalysisRequest {
  /// Constroi a partir do JSON retornado pela API (campos snake_case, datas
  /// ISO-8601, `images` ja como lista de URLs).
  static AnalysisRequest fromApi(Map<String, dynamic> data) {
    return AnalysisRequest(
      id: (data['id'] ?? '').toString(),
      name: data['name'] ?? '',
      notes: data['notes'] ?? '',
      userId: data['user_id'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      imageUrls: List<String>.from(data['images'] ?? const [])
          .map(ImageUrlResolver.resolve)
          .toList(),
      createdAt: _parseDate(data['created_at']),
      speciesName: data['species_name'],
      careInstructions: data['care_instructions'],
      adminNotes: data['admin_notes'],
      reviewedAt: _parseDate(data['reviewed_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
