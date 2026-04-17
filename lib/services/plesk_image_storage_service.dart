import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'i_image_storage_service.dart';

class PleskImageStorageService implements IImageStorageService {
  final String uploadUrl;

  const PleskImageStorageService({
    this.uploadUrl = 'https://api.devjoelchagas.com.br/index.php',
  });

  @override
  Future<List<String>> uploadImages(
      List<File> images,
      String userId, {
        String? analysisId,
      }) async {
    final urls      = <String>[];
    final folderName = analysisId ?? userId;

    for (final image in images) {
      // Nome do arquivo: userId + timestamp
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Campos enviados ao PHP
      request.fields['title']       = fileName;
      request.fields['analysis_id'] = folderName;

      // Arquivo de imagem
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      final streamed  = await request.send();
      final response  = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception(
          'Erro HTTP ${response.statusCode} ao fazer upload da imagem.',
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        throw Exception(
          data['message'] ?? 'Erro desconhecido no upload da imagem.',
        );
      }

      urls.add(data['data']['url'] as String);
    }

    return urls;
  }
}
