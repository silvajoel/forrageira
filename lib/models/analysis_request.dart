import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'analysis_request.freezed.dart';
part 'analysis_request.g.dart';

@freezed
class AnalysisRequest with _$AnalysisRequest {
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

extension AnalysisRequestFirestore on AnalysisRequest {
  static AnalysisRequest fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalysisRequest(
      id: doc.id,
      name: data['name'] ?? '',
      notes: data['notes'] ?? '',
      userId: data['user_id'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      imageUrls: List<String>.from(data['images'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      speciesName: data['species_name'],
      careInstructions: data['care_instructions'],
      adminNotes: data['admin_notes'],
      reviewedAt: (data['reviewed_at'] as Timestamp?)?.toDate(),
    );
  }
}