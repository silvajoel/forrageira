import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'i_image_storage_service.dart';

class SupabaseImageStorageService implements IImageStorageService {
  final SupabaseClient _client;

  const SupabaseImageStorageService(this._client);

  @override
  Future<List<String>> uploadImages(List<File> images, String userId) async {
    final urls = <String>[];

    for (final image in images) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'images/$userId/$fileName.jpg';

      await _client.storage.from('forrageiras').upload(path, image);

      urls.add(_client.storage.from('forrageiras').getPublicUrl(path));
    }

    return urls;
  }
}