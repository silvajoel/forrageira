class PendingAnalysisDraft {
  final String localId;
  final String name;
  final String notes;
  final String userId;
  final double latitude;
  final double longitude;
  final List<String> imagePaths;
  final DateTime createdAt;

  const PendingAnalysisDraft({
    required this.localId,
    required this.name,
    required this.notes,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.imagePaths,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'name': name,
      'notes': notes,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'image_paths': imagePaths,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingAnalysisDraft.fromJson(Map<String, dynamic> json) {
    return PendingAnalysisDraft(
      localId: (json['local_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      imagePaths: List<String>.from(json['image_paths'] ?? const []),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
