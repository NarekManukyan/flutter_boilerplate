import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../utils/color_utils.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  MediaQueryData get media => MediaQuery.of(this);

  double get height => media.size.height;

  double get bodyHeight => height - 100;

  double get width => media.size.width;

  double get topPadding => media.padding.top;

  double get bottomPadding => media.padding.bottom;

  bool get isDarkMode => media.platformBrightness == Brightness.dark;
}

extension ThemeDataHelper on ThemeData {
  TextStyle get headlineLarge => textTheme.headlineLarge!;

  TextStyle get headlineMedium => textTheme.headlineMedium!;

  TextStyle get headlineSmall => textTheme.headlineSmall!;

  TextStyle get titleLarge => textTheme.titleLarge!;

  TextStyle get titleMedium => textTheme.titleMedium!;

  TextStyle get titleSmall => textTheme.titleSmall!;

  TextStyle get labelSmall => textTheme.labelSmall!;

  TextStyle get labelMedium => textTheme.labelMedium!;

  TextStyle get labelLarge => textTheme.labelLarge!;

  TextStyle get button => textTheme.labelSmall!;

  TextStyle get bodySmall => textTheme.bodySmall!;

  TextStyle get bodyMedium => textTheme.bodyMedium!;

  TextStyle get bodyLarge => textTheme.bodyLarge!;

  ButtonStyle get elevatedButtonStyle => elevatedButtonTheme.style!;

  ButtonStyle get textButtonStyle => textButtonTheme.style!;
}

extension ElevatedButtonHelper on ButtonStyle {
  ButtonStyle buttonColor(Color color) => copyWith(
        shadowColor: MaterialStateProperty.all(color),
        foregroundColor: MaterialStateProperty.all(AppColors.white),
        backgroundColor: MaterialStateProperty.resolveWith(
          (states) {
            return states.contains(MaterialState.disabled)
                ? color.withOpacity(0.5)
                : color;
          },
        ),
      );

  ButtonStyle elevationSize(double elevation) {
    return copyWith(
      elevation: MaterialStateProperty.all(
        elevation,
      ),
    );
  }

  ButtonStyle paddingAll(double padding) {
    return copyWith(
      padding: MaterialStateProperty.all(
        EdgeInsets.all(padding),
      ),
    );
  }

  ButtonStyle paddingVertical(double padding) {
    return copyWith(
      padding: MaterialStateProperty.all(
        EdgeInsets.symmetric(vertical: padding),
      ),
    );
  }

  ButtonStyle get removePaddings => copyWith(
        padding: MaterialStateProperty.all(
          EdgeInsets.zero,
        ),
      );

  ButtonStyle textColor(
    Color color,
  ) {
    return copyWith(
      foregroundColor: MaterialStateProperty.all(
        color,
      ),
    );
  }
}

// usage example: context.h3.regular.white
extension TextStyleHelpers on TextStyle {
  TextStyle get white => copyWith(color: AppColors.white);

  TextStyle get yellow => copyWith(color: AppColors.yellow);

  TextStyle get darkGray => copyWith(color: AppColors.darkGray);

  TextStyle get mediumGray => copyWith(color: AppColors.grayMedium);

  TextStyle get charcoal => copyWith(color: AppColors.charcoal);

  TextStyle get red => copyWith(color: AppColors.red);

  TextStyle get chalkboardBlack => copyWith(color: AppColors.chalkboardBlack);

  TextStyle get burgundy => copyWith(color: AppColors.burgundy);

  TextStyle get lightGray => copyWith(color: AppColors.lightGray);

  TextStyle get error => copyWith(color: AppColors.error);

  TextStyle dynamic({
    Color lightColor = AppColors.grayMedium,
    Color darkColor = AppColors.darkGray,
    bool invertColor = false,
  }) {
    return copyWith(
      color: brightnessColor(
        lightColor: lightColor,
        darkColor: darkColor,
        invert: invertColor,
      ),
    );
  }

  TextStyle size([double? fontSize]) => copyWith(fontSize: fontSize);

  TextStyle get regular => copyWith(fontWeight: FontWeight.normal);

  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
}

extension GlobalKeyEx on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();

    return translation != null && renderObject?.paintBounds != null
        ? renderObject!.paintBounds.shift(Offset(translation.x, translation.y))
        : null;
  }
}
