import 'package:flutter/cupertino.dart';
import 'package:pinput/pinput.dart';

import '../../core/src/constants/constants.dart';

PinTheme pinThem(Color borderColor) => PinTheme(
      width: 50,
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(kBorderRadius8px),
      ),
    );
