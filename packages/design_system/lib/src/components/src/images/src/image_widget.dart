import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  const ImageWidget({
    super.key,
    required this.image,
    this.shape,
    this.border,
    this.borderRadius,
  });

  final String image;
  final BoxShape? shape;
  final BoxBorder? border;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ExtendedImage(
          image: ExtendedNetworkImageProvider(
            image,
            cache: true,
            timeRetry: const Duration(seconds: 2),
          ),
          fit: BoxFit.cover,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          shape: shape,
          border: border,
          borderRadius: borderRadius,
        );
      },
    );
  }
}
