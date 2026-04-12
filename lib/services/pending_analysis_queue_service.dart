import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_analysis_draft.dart';
import 'i_forage_service.dart';
import 'i_image_storage_service.dart';

class PendingAnalysisQueueService extends ChangeNotifier {
  static const String _storageKey = 'pending_analysis_queue_v1';

  final List<PendingAnalysisDraft> _items = [];
  bool _loaded = false;
  bool _isSyncing = false;

  List<PendingAnalysisDraft> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;
  bool get isSyncing => _isSyncing;

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const [];

    _items
      ..clear()
      ..addAll(
        rawItems.map((item) {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          return PendingAnalysisDraft.fromJson(decoded);
        }),
      );

    _loaded = true;
    notifyListeners();
  }

  List<PendingAnalysisDraft> itemsForUser(String userId) {
    return _items.where((item) => item.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int pendingCountForUser(String userId) => itemsForUser(userId).length;

  Future<void> enqueue({
    required String name,
    required String notes,
    required String userId,
    required double latitude,
    required double longitude,
    required List<File> images,
  }) async {
    await ensureLoaded();

    final localId =
        'offline_${DateTime.now().millisecondsSinceEpoch}_${_items.length}';
    final savedImagePaths = await _persistImages(localId, images);

    _items.add(
      PendingAnalysisDraft(
        localId: localId,
        name: name,
        notes: notes,
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        imagePaths: savedImagePaths,
        createdAt: DateTime.now(),
      ),
    );

    await _save();
    notifyListeners();
  }

  Future<void> syncPendingAnalyses({
    required IForageService forageService,
    required IImageStorageService imageStorageService,
  }) async {
    await ensureLoaded();

    if (_isSyncing || _items.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    final snapshot = List<PendingAnalysisDraft>.from(_items);

    try {
      for (final item in snapshot) {
        try {
          final files = item.imagePaths
              .map((imagePath) => File(imagePath))
              .where((file) => file.existsSync())
              .toList();

          if (files.length != item.imagePaths.length || files.isEmpty) {
            continue;
          }

          final imageUrls = await imageStorageService.uploadImages(
            files,
            item.userId,
            analysisId: item.localId,
          );

          await forageService.createAnalysisRequest(
            name: item.name,
            notes: item.notes,
            userId: item.userId,
            latitude: item.latitude,
            longitude: item.longitude,
            imageUrls: imageUrls,
          );

          await _removeLocalItem(item.localId);
        } catch (_) {
          // Mantem na fila e tenta novamente quando houver nova oportunidade.
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<List<String>> _persistImages(String localId, List<File> images) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final folder = Directory(
      path.join(baseDir.path, 'offline_analysis_queue', localId),
    );

    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }

    final copiedPaths = <String>[];

    for (var index = 0; index < images.length; index++) {
      final source = images[index];
      final extension = path.extension(source.path);
      final targetPath = path.join(folder.path, 'image_$index$extension');
      final copied = await source.copy(targetPath);
      copiedPaths.add(copied.path);
    }

    return copiedPaths;
  }

  Future<void> _removeLocalItem(String localId) async {
    final index = _items.indexWhere((item) => item.localId == localId);
    if (index == -1) return;

    final item = _items.removeAt(index);
    final folder = Directory(
      path.dirname(item.imagePaths.isNotEmpty ? item.imagePaths.first : ''),
    );
    if (folder.path.isNotEmpty && folder.existsSync()) {
      await folder.delete(recursive: true);
    }

    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, encoded);
  }
}
