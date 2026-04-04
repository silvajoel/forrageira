import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AuditLogService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> log({
    required String action,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    await _firestore.collection('admin_audit_logs').add({
      'action': action,
      'target_id': targetId,
      'actor_uid': user?.uid,
      'actor_email': user?.email,
      'metadata': metadata ?? <String, dynamic>{},
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecent({int limit = 30}) {
    return _firestore
        .collection('admin_audit_logs')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots();
  }
}
