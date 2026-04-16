import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forrageira/models/app_notification.dart';

class AppNotificationService {
  final FirebaseFirestore _firestore;

  AppNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> notifyAdminsNewAnalysis({
    required String analysisId,
    required String forageName,
    required String requesterId,
  }) async {
    await _firestore.collection('app_notifications').add({
      'title': 'Nova análise cadastrada',
      'message': 'Uma nova forrageira "$forageName" foi enviada para análise.',
      'recipient_type': 'role',
      'recipient_id': 'admin',
      'analysis_id': analysisId,
      'requester_id': requesterId,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Notifica o próprio usuário que sua análise foi recebida e está em processamento.
  Future<void> notifyUserAnalysisReceived({
    required String analysisId,
    required String userId,
    required String forageName,
  }) async {
    await _firestore.collection('app_notifications').add({
      'title': 'Análise recebida!',
      'message':
      'Sua análise de "$forageName" foi recebida com sucesso e está aguardando revisão.',
      'recipient_type': 'user',
      'recipient_id': userId,
      'analysis_id': analysisId,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> notifyUserAnalysisCompleted({
    required String analysisId,
    required String userId,
    required String forageName,
  }) async {
    await _firestore.collection('app_notifications').add({
      'title': 'Análise concluída',
      'message': 'A análise da forrageira "$forageName" foi finalizada.',
      'recipient_type': 'user',
      'recipient_id': userId,
      'analysis_id': analysisId,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }


  Future<void> notifyUserAnalysisReopened({
    required String analysisId,
    required String userId,
    required String forageName,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    await _firestore.collection('app_notifications').add({
      'title': 'Análise reaberta para ajustes',
      'message': cleanReason.isEmpty
          ? 'A análise da forrageira "$forageName" foi reaberta para ajustes.'
          : 'A análise da forrageira "$forageName" foi reaberta para ajustes. Motivo: $cleanReason',
      'recipient_type': 'user',
      'recipient_id': userId,
      'analysis_id': analysisId,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppNotification>> watchUserNotifications({
    required String userId,
    int limit = 50,
  }) {
    return _firestore
        .collection('app_notifications')
        .where('recipient_type', isEqualTo: 'user')
        .where('recipient_id', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<AppNotification>> watchAdminRoleNotifications({int limit = 50}) {
    return _firestore
        .collection('app_notifications')
        .where('recipient_type', isEqualTo: 'role')
        .where('recipient_id', isEqualTo: 'admin')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> markAsRead(String notificationId) {
    return _firestore.collection('app_notifications').doc(notificationId).update({
      'read': true,
    });
  }

  /// Marca como lidas todas as notificações do usuário (e, se [includeAdminRole], as de papel admin).
  Future<void> markAllAsRead({
    required String userId,
    required bool includeAdminRole,
  }) async {
    final batch = _firestore.batch();
    var n = 0;

    void queueDocs(QuerySnapshot<Map<String, dynamic>> snap) {
      for (final d in snap.docs) {
        if (d.data()['read'] == true) continue;
        batch.update(d.reference, {'read': true});
        n++;
        if (n >= 450) break;
      }
    }

    final userSnap = await _firestore
        .collection('app_notifications')
        .where('recipient_type', isEqualTo: 'user')
        .where('recipient_id', isEqualTo: userId)
        .get();
    queueDocs(userSnap);

    if (includeAdminRole && n < 450) {
      final adminSnap = await _firestore
          .collection('app_notifications')
          .where('recipient_type', isEqualTo: 'role')
          .where('recipient_id', isEqualTo: 'admin')
          .get();
      queueDocs(adminSnap);
    }

    if (n > 0) {
      await batch.commit();
    }
  }
}