import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import '../../gen/colors.gen.dart';

part 'theme_colors.tailor.dart';

@Tailor(requireStaticConst: true)
class _$ThemeColors {
  static const List<Color> background = [
    AppColors.blackHeadlines,
    AppColors.gray,
  ];
}
