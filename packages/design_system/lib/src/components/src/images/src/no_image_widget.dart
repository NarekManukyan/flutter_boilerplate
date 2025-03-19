import 'package:flutter/material.dart';

import '../../../../../design_system.dart';

class NoImageWidget extends StatelessWidget {
  const NoImageWidget({
    super.key,
    required this.letter,
    required this.letterStyle,
    required this.letterColor,
    required this.backgroundColor,
    this.shape,
    this.border,
    this.borderRadius,
  });

  final String letter;
  final TextStyle letterStyle;
  final Color letterColor;
  final Color backgroundColor;
  final BoxShape? shape;
  final BoxBorder? border;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: border ?? Border.all(color: context.borderNeutralLight),
        borderRadius: borderRadius,
        shape: shape ?? BoxShape.rectangle,
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          letter,
          style: letterStyle.setColor(letterColor),
        ),
      ),
    );
  }
}
