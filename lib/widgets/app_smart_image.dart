import 'package:flutter/widgets.dart';

import 'app_smart_image_stub.dart'
    if (dart.library.io) 'app_smart_image_io.dart' as impl;

class AppSmartImage extends StatelessWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  const AppSmartImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildSmartImage(
      source: source,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
}
