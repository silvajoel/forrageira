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

  return Image.network(
    resolvedSource,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
    loadingBuilder: loadingBuilder,
  );
}
