import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';

abstract class IForageService extends ChangeNotifier {
  Future<void> createAnalysisRequest({
    required String name,
    required String notes,
    required String userId,
    required double latitude,
    required double longitude,
    List<String>? imageUrls,
  });

  Stream<List<AnalysisRequest>> watchUserForages(String userId, {int limit = 3});
  Stream<List<AnalysisRequest>> watchAllUserForages(String userId, {int limit = 20});
}