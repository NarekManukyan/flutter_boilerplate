import 'package:flutter/material.dart';

import '../extensions/context_extension.dart';
import '../providers/screen_service.dart';
import '../themes/app_colors.dart';

enum ContrastPreference {
  none,
  light,
  dark,
}

const _kMinContrastModifierRange = 0.35;
const _kMaxContrastModifierRange = 0.65;

/// Returns black or white depending on whether the source color is darker
/// or lighter. If darker, will return white. If lighter, will return
/// black. If the color is within 35-65% of the spectrum and a prefer
/// value is specified, then white or black will be preferred.
Color blackOrWhiteContrastColor(
  Color sourceColor, {
  ContrastPreference prefer = ContrastPreference.none,
}) {
  // Will return a value between 0.0 (black) and 1.0 (white)
  final value = (((sourceColor.red * 299.0) +
              (sourceColor.green * 587.0) +
              (sourceColor.blue * 114.0)) /
          1000.0) /
      255.0;
  if (prefer != ContrastPreference.none) {
    if (value >= _kMinContrastModifierRange &&
        value <= _kMaxContrastModifierRange) {
      return prefer == ContrastPreference.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000);
    }
  }
  return value > 0.6 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}

Color brightnessColor({
  Color lightColor = AppColors.white,
  Color darkColor = AppColors.darkGray,
  bool invert = false,
}) {
  var isDarkMode = router.navigatorKey.currentContext!.isDarkMode;
  if (invert) {
    isDarkMode = !isDarkMode;
  }
  return isDarkMode ? lightColor : darkColor;
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}
