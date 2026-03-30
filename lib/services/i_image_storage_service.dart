import 'dart:io';

abstract class IImageStorageService {
  /// [images]     — lista de arquivos a enviar
  /// [userId]     — UID do usuário autenticado
  /// [analysisId] — ID da análise (usado como subpasta no servidor)
  Future<List<String>> uploadImages(
      List<File> images,
      String userId, {
        String? analysisId,
      });
}
