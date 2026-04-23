import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'i_image_storage_service.dart';

class ImageUploadException implements Exception {
  final String message;
  final bool isRetryable;
  final int? statusCode;

  const ImageUploadException(
    this.message, {
    this.isRetryable = false,
    this.statusCode,
  });

  @override
  String toString() => message;
}

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

      http.StreamedResponse streamed;
      http.Response response;

      try {
        streamed = await request.send().timeout(const Duration(seconds: 30));
        response = await http.Response.fromStream(streamed)
            .timeout(const Duration(seconds: 30));
      } on SocketException {
        throw const ImageUploadException(
          'Falha de conexao ao enviar a imagem. Verifique sua internet.',
          isRetryable: true,
        );
      } on HttpException {
        throw const ImageUploadException(
          'Falha de comunicacao com o servidor de imagens.',
          isRetryable: true,
        );
      } on TimeoutException {
        throw const ImageUploadException(
          'O servidor demorou demais para responder ao upload da imagem.',
          isRetryable: true,
        );
      }

      if (response.statusCode != 200) {
        final serverMessage = _extractMessage(response.body);
        throw ImageUploadException(
          serverMessage ??
              'Erro HTTP ${response.statusCode} ao fazer upload da imagem.',
          isRetryable: response.statusCode >= 500,
          statusCode: response.statusCode,
        );
      }

      late final Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw const ImageUploadException(
          'A API de upload retornou uma resposta invalida.',
          isRetryable: true,
        );
      }

      if (data['status'] != 'success') {
        throw ImageUploadException(
          (data['message'] as String?) ??
              'Erro desconhecido no upload da imagem.',
          isRetryable: false,
        );
      }

      urls.add(data['data']['url'] as String);
    }

    return urls;
  }

  String? _extractMessage(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } on FormatException {
      return null;
    }

    return null;
  }
}
