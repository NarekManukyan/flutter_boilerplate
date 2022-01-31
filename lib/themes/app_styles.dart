import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

const BoxDecoration splashScreenGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFEAE1C),
      Color(0xFFFF9921),
      Color(0xFFFF9921),
      Color(0xFFFEAE1C),
    ],
  ),
);

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.all(16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  textStyle: const TextStyle(
    fontFamily: FontFamily.CeraPro,
    fontWeight: FontWeight.w500,
  ),
);

final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  primary: AppColors.red,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.all(16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  textStyle: const TextStyle(
    fontFamily: FontFamily.CeraPro,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  ),
);

final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.all(16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  textStyle: const TextStyle(
    fontFamily: FontFamily.CeraPro,
    fontWeight: FontWeight.w500,
  ),
).copyWith(
  side: MaterialStateProperty.resolveWith<BorderSide>(
    (states) {
      if (states.contains(MaterialState.pressed)) {
        return const BorderSide(color: AppColors.red);
      }
      return const BorderSide();
    },
  ),
);

const TextStyle pinThemeTextStyle = TextStyle(
  color: AppColors.charcoal,
  fontSize: 27,
  fontFamily: FontFamily.CeraPro,
);

final BorderRadius textFieldBorder = BorderRadius.circular(20);
