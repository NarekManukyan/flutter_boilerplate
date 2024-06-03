import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'theme_colors.tailor.dart';

@tailorMixin
class CustomTheme extends ThemeExtension<CustomTheme>
    with _$CustomThemeTailorMixin {
  CustomTheme({
    required this.background,
  });

  @override
  final Color background;
}
