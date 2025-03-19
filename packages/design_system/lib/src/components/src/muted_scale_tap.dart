// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';

import '../../../design_system.dart';

const double _DEFAULT_SCALE_MIN_VALUE = 0.90;
const double _DEFAULT_OPACITY_MIN_VALUE = 0.90;
final Curve _DEFAULT_SCALE_CURVE = CurveSpring();
const Curve _DEFAULT_OPACITY_CURVE = Curves.ease;
const Duration _DEFAULT_DURATION = kAnimationDuration;

class MutedScaleTap extends ScaleTap {
  MutedScaleTap({
    required super.child,
    super.onPressed,
    super.onLongPress,
  }) : super(
          enableFeedback: false,
          duration: _DEFAULT_DURATION,
          scaleMinValue: _DEFAULT_SCALE_MIN_VALUE,
          opacityMinValue: _DEFAULT_OPACITY_MIN_VALUE,
          scaleCurve: _DEFAULT_SCALE_CURVE,
          opacityCurve: _DEFAULT_OPACITY_CURVE,
        );
}
