import 'dart:math' as math;

import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  MediaQueryData get media => MediaQuery.of(this);

  double get height => media.size.height;

  double get bodyHeight => height - 100;

  double get width => media.size.width;

  double get topPadding => media.padding.top;

  double get bottomPadding => media.padding.bottom;

  double get bottomSecurePadding => math.max(
        media.viewInsets.bottom,
        math.max(bottomPadding, 16),
      );

  bool get isDarkMode => media.platformBrightness == Brightness.dark;
}

extension ThemeDataHelper on ThemeData {
  ButtonStyle get elevatedButtonStyle => elevatedButtonTheme.style!;

  ButtonStyle get textButtonStyle => textButtonTheme.style!;

  ButtonStyle get outlinedButtonStyle => outlinedButtonTheme.style!;
}

extension TextStyleHelpers on TextStyle {
  TextStyle setColor([Color? color]) => copyWith(color: color);
}
