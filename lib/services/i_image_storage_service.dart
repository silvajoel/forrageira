import 'dart:io';

abstract class IImageStorageService {
  Future<List<String>> uploadImages(List<File> images, String userId);
}