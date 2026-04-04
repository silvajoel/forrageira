import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] == true,
      analysisId: data['analysis_id'] as String?,
    );
  }
}