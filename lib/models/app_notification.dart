class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? analysisId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.analysisId,
  });

  /// Constroi a partir do JSON da API (`read` ja normalizado de `read_status`).
  factory AppNotification.fromApi(Map<String, dynamic> data) {
    return AppNotification(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      createdAt: _parseDate(data['created_at']) ?? DateTime.now(),
      read: data['read'] == true,
      analysisId: data['analysis_id'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
