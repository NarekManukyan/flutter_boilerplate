import 'package:flutter/material.dart';

import '../../theme/src/theme_tailor/custom_theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    required this.isLoading,
    this.strokeWidth = 5,
    this.width = 36,
    this.height = 36,
    this.loadingColor,
  });

  final bool isLoading;
  final double strokeWidth;
  final double width;
  final double height;
  final Color? loadingColor;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: SizedBox(
              width: width,
              height: height,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                color: loadingColor ?? context.borderPrimary,
              ),
            ),
          )
        : const SizedBox();
  }
}
