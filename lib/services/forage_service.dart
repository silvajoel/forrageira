import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'i_forage_service.dart';

class ForageService extends ChangeNotifier implements IForageService {
  final FirebaseFirestore _firestore;

  ForageService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createAnalysisRequest({
    required String name,
    required String notes,
    required String userId,
    required double latitude,
    required double longitude,
    List<String>? imageUrls,
  }) async {
    await _firestore.collection('analysis_requests').add({
      'name': name,
      'notes': notes,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'images': imageUrls,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AnalysisRequest>> watchUserForages(String userId, {int limit = 3}) {
    return _firestore
        .collection('analysis_requests')
        .where('user_id', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
        .map(AnalysisRequestFirestore.fromFirestore)
        .toList());
  }

  @override
  Stream<List<AnalysisRequest>> watchAllUserForages(String userId, {int limit = 20}) {
    return _firestore
        .collection('analysis_requests')
        .where('user_id', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
        .map(AnalysisRequestFirestore.fromFirestore)
        .toList());
  }
}