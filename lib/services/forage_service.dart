import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/services/app_notification_service.dart';
import 'package:forrageira/services/audit_log_service.dart';

import 'i_forage_service.dart';

class ForageService extends ChangeNotifier implements IForageService {
  final FirebaseFirestore _firestore;
  final AppNotificationService _notificationService;
  final AuditLogService _auditLogService;

  ForageService({
    FirebaseFirestore? firestore,
    AppNotificationService? notificationService,
    AuditLogService? auditLogService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? AppNotificationService(),
        _auditLogService = auditLogService ?? AuditLogService();

  @override
  Future<void> createAnalysisRequest({
    required String name,
    required String notes,
    required String userId,
    required double latitude,
    required double longitude,
    List<String>? imageUrls,
  }) async {
    final requestRef = await _firestore.collection('analysis_requests').add({
      'name': name,
      'notes': notes,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'images': imageUrls,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    try {
      await _notificationService.notifyAdminsNewAnalysis(
        analysisId: requestRef.id,
        forageName: name,
        requesterId: userId,
      );
    } catch (e) {
      debugPrint('Falha ao notificar admins: $e');
    }

    try {
      await _notificationService.notifyUserAnalysisReceived(
        analysisId: requestRef.id,
        userId: userId,
        forageName: name,
      );
    } catch (e) {
      debugPrint('Falha ao notificar usuario sobre recebimento: $e');
    }
  }

  @override
  Future<void> finalizeAnalysisRequest({
    required String requestId,
    required String speciesName,
    required String careInstructions,
    required String adminNotes,
  }) async {
    final docRef = _firestore.collection('analysis_requests').doc(requestId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Analise nao encontrada');
    }

    final data = snapshot.data() as Map<String, dynamic>;
    final userId = data['user_id'] as String?;
    final forageName = (data['name'] as String?) ?? 'forrageira';
    if (userId == null || userId.isEmpty) {
      throw Exception('Usuario da analise invalido');
    }

    await _notificationService.notifyUserAnalysisCompleted(
      analysisId: requestId,
      userId: userId,
      forageName: forageName,
    );

    await docRef.update({
      'status': 'completed',
      'species_name': speciesName,
      'care_instructions': careInstructions,
      'admin_notes': adminNotes,
      'reviewed_at': FieldValue.serverTimestamp(),
    });

    await _auditLogService.log(
      action: 'Finalizou analise',
      targetId: requestId,
      metadata: {
        'species_name': speciesName,
        'user_id': userId,
      },
    );
  }

  @override
  Stream<List<AnalysisRequest>> watchUserForages(
    String userId, {
    int limit = 3,
  }) {
    return _firestore
        .collection('analysis_requests')
        .where('user_id', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snap) => _sortByCreatedAtDesc(
              snap.docs.map(AnalysisRequestFirestore.fromFirestore).toList(),
            ));
  }

  @override
  Stream<List<AnalysisRequest>> watchAllUserForages(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('analysis_requests')
        .where('user_id', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snap) => _sortByCreatedAtDesc(
              snap.docs.map(AnalysisRequestFirestore.fromFirestore).toList(),
            ));
  }

  @override
  Stream<List<AnalysisRequest>> watchAllRequests({int limit = 100}) {
    return _firestore
        .collection('analysis_requests')
        .limit(limit)
        .snapshots()
        .map((snap) => _sortByCreatedAtDesc(
              snap.docs.map(AnalysisRequestFirestore.fromFirestore).toList(),
            ));
  }

  @override
  Future<AnalysisRequest> getById(String id) async {
    final doc = await _firestore.collection('analysis_requests').doc(id).get();

    if (!doc.exists) {
      throw Exception('Analise nao encontrada');
    }

    return AnalysisRequestFirestore.fromFirestore(doc);
  }

  List<AnalysisRequest> _sortByCreatedAtDesc(List<AnalysisRequest> items) {
    items.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return items;
  }
}
