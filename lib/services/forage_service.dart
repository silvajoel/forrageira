import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ForageService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAnalysisRequest({
    required String name,
    required String notes,
    required String userId,
    required double latitude,
    required double longitude,
    String? imageUrl,
  }) async {

    await _firestore.collection('analysis_requests').add({
      'name': name,
      'notes': notes,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl ?? "",
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

  }
}