import 'dart:io';

import 'package:flutter/widgets.dart';

import '../utils/image_url_resolver.dart';

Widget buildSmartImage({
  required String source,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  ImageLoadingBuilder? loadingBuilder,
}) {
  final resolvedSource = ImageUrlResolver.resolve(source);
  final normalized = resolvedSource.toLowerCase();
  final isRemote = normalized.startsWith('http://') ||
      normalized.startsWith('https://');

  if (isRemote) {
    return Image.network(
      resolvedSource,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }

  return Image.file(
    File(resolvedSource),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
