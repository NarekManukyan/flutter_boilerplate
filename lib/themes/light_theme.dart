import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gen/colors.gen.dart';
import '../gen/fonts.gen.dart';
import 'theme_tailor/theme_colors.dart';

final base = ThemeData.light(useMaterial3: false);
const scaffoldBackgroundColor = AppColors.charcoal;

final _customThemeLight = CustomTheme(background: AppColors.white);

final lightTheme = base.copyWith(
  shadowColor: AppColors.yellow,
  extensions: [_customThemeLight],
  colorScheme: base.colorScheme.copyWith(
    primary: AppColors.white,
    onPrimary: AppColors.charcoal,
  ),
  tabBarTheme: TabBarTheme(
    unselectedLabelStyle: base.primaryTextTheme.labelSmall!.copyWith(
      color: AppColors.white,
    ),
    labelStyle: const TextStyle(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.normal,
      fontSize: 16,
      height: 1,
    ),
    indicator: BoxDecoration(
      borderRadius: BorderRadius.circular(13),
      color: AppColors.white,
    ),
    indicatorSize: TabBarIndicatorSize.tab,
    labelColor: AppColors.charcoal,
    unselectedLabelColor: AppColors.white,
    labelPadding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 5,
    ),
  ),
  primaryColor: AppColors.yellow,
  // shadowColor: Colors.grey[300],
  scaffoldBackgroundColor: AppColors.white,
  dividerColor: AppColors.extraLightGray,
  dividerTheme: base.dividerTheme.copyWith(
    space: 1,
    indent: 24,
    endIndent: 24,
    color: AppColors.lightGray,
  ),
  primaryIconTheme: base.primaryIconTheme.copyWith(color: AppColors.charcoal),
  iconTheme: base.iconTheme.copyWith(color: AppColors.charcoal),
  appBarTheme: base.appBarTheme.copyWith(
    color: AppColors.white,
    centerTitle: true,
    elevation: 0,
    iconTheme: const IconThemeData(
      color: AppColors.charcoal,
    ),
    titleTextStyle: base.primaryTextTheme.titleSmall!.copyWith(
      fontFamily: FontFamily.mulish,
      color: AppColors.charcoal,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      letterSpacing: -.4,
      height: 1.1,
    ),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    toolbarTextStyle: base.textTheme
        .copyWith(
          labelSmall: base.textTheme.labelSmall!.copyWith(
            fontFamily: FontFamily.mulish,
            color: AppColors.charcoal,
            fontWeight: FontWeight.bold,
          ),
          titleSmall: base.textTheme.titleSmall!.copyWith(
            fontFamily: FontFamily.mulish,
            color: AppColors.chalkboardBlack,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: base.textTheme.headlineSmall!.copyWith(
            fontFamily: FontFamily.mulish,
            color: AppColors.charcoal,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: base.textTheme.titleLarge!.copyWith(
            fontFamily: FontFamily.mulish,
            color: AppColors.charcoal,
            fontWeight: FontWeight.w500,
          ),
        )
        .bodyMedium,
  ),
  bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
    backgroundColor: AppColors.white,
    elevation: 0,
  ),
  chipTheme: base.chipTheme.copyWith(
    backgroundColor: Colors.transparent,
    labelPadding: const EdgeInsets.symmetric(horizontal: 20),
    labelStyle: const TextStyle(
      color: AppColors.charcoal,
      fontWeight: FontWeight.w500,
      fontFamily: FontFamily.mulish,
    ),
    selectedColor: AppColors.charcoal,
    secondaryLabelStyle: const TextStyle(
      color: AppColors.charcoal,
      fontWeight: FontWeight.w500,
      fontFamily: FontFamily.mulish,
    ),
    secondarySelectedColor: Colors.transparent,
  ),
  sliderTheme: base.sliderTheme.copyWith(
    activeTrackColor: AppColors.red,
    inactiveTrackColor: AppColors.extraLightGray,
    overlayColor: Colors.transparent,
    thumbColor: AppColors.red,
    thumbShape: SliderComponentShape.noOverlay,
    valueIndicatorColor: AppColors.red,
  ),
  textSelectionTheme: base.textSelectionTheme.copyWith(
    cursorColor: AppColors.yellow,
    selectionHandleColor: AppColors.yellow,
  ),
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: AppColors.yellow,
  ),
  brightness: Brightness.light,
  inputDecorationTheme: base.inputDecorationTheme.copyWith(
    errorStyle: const TextStyle(
      color: AppColors.red,
      fontFamily: FontFamily.mulish,
    ),
    hintStyle: base.primaryTextTheme.bodyLarge!.copyWith(
      color: AppColors.darkGray,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: -.32,
      height: 1.25,
    ),
    fillColor: AppColors.extraLightGray,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.transparent,
        width: 2,
      ),
    ),
    enabledBorder: const UnderlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.transparent,
        width: 0,
      ),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.transparent,
        width: 0,
      ),
    ),
    filled: true,
    labelStyle: const TextStyle(
      color: AppColors.darkGray,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: -.32,
      height: 1.25,
    ),
  ),
  buttonTheme: base.buttonTheme.copyWith(
    textTheme: ButtonTextTheme.primary,
    buttonColor: AppColors.white,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      textStyle: WidgetStateProperty.resolveWith(
        (states) {
          return states.contains(WidgetState.disabled)
              ? TextStyle(
                  color: AppColors.burgundy.withOpacity(0.5),
                  fontFamily: FontFamily.mulish,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.1,
                )
              : const TextStyle(
                  color: AppColors.burgundy,
                  fontFamily: FontFamily.mulish,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.1,
                );
        },
      ),
      shape: WidgetStateProperty.resolveWith((state) {
        return const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        );
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled)
            ? AppColors.burgundy.withOpacity(0.4)
            : AppColors.burgundy;
      }),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          return states.contains(WidgetState.disabled)
              ? AppColors.extraLightGray.withOpacity(0.4)
              : AppColors.extraLightGray;
        },
      ),
      overlayColor: WidgetStateProperty.all(
        AppColors.grayMedium.withOpacity(.5),
      ),
    ),
  ),
  tooltipTheme: TooltipThemeData(
    preferBelow: false,
    decoration: BoxDecoration(
      color: AppColors.burgundy,
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      shadowColor: WidgetStateProperty.all(AppColors.yellow),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      overlayColor:
          WidgetStateProperty.all(AppColors.grayMedium.withOpacity(.5)),
      elevation: WidgetStateProperty.all(0),
      textStyle: WidgetStateProperty.resolveWith(
        (states) {
          return const TextStyle(
            color: AppColors.white,
            fontFamily: FontFamily.mulish,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            height: 1.1,
          );
        },
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      foregroundColor: WidgetStateProperty.all(AppColors.white),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          return states.contains(WidgetState.disabled)
              ? AppColors.yellow.withOpacity(0.5)
              : AppColors.yellow;
        },
      ),
    ),
  ),
  textTheme: base.primaryTextTheme.copyWith(
    headlineLarge: base.primaryTextTheme.headlineLarge!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.bold,
      fontSize: 26,
    ),
    headlineMedium: base.primaryTextTheme.headlineMedium!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.bold,
      fontSize: 38,
      letterSpacing: -.76,
      height: 1,
    ),
    headlineSmall: base.primaryTextTheme.headlineSmall!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.bold,
      fontSize: 28,
      letterSpacing: -.56,
      height: 1,
    ),
    titleLarge: base.primaryTextTheme.titleLarge!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.normal,
      fontSize: 26,
      letterSpacing: -.52,
      height: 1,
    ),
    titleMedium: base.primaryTextTheme.titleMedium!.copyWith(
      fontFamily: FontFamily.mulish,
      color: AppColors.charcoal,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      letterSpacing: -.48,
      height: 1.2,
    ),
    titleSmall: base.primaryTextTheme.titleSmall!.copyWith(
      fontFamily: FontFamily.mulish,
      color: AppColors.charcoal,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      letterSpacing: -.4,
      height: 1.1,
    ),
    labelLarge: base.primaryTextTheme.labelLarge!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      height: 1.25,
      letterSpacing: -.32,
    ),
    labelMedium: base.primaryTextTheme.labelMedium!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.25,
      letterSpacing: -.32,
    ),
    labelSmall: const TextStyle(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      height: 1.1,
    ),
    bodyLarge: base.primaryTextTheme.bodyLarge!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: -.32,
      height: 1.25,
    ),
    bodyMedium: base.primaryTextTheme.bodyMedium!.copyWith(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.normal,
      fontSize: 14,
      letterSpacing: -.16,
      height: 1.25,
    ),
    bodySmall: const TextStyle(
      color: AppColors.charcoal,
      fontFamily: FontFamily.mulish,
      fontWeight: FontWeight.normal,
      fontSize: 12,
      height: 1.1,
      letterSpacing: -.16,
    ),
  ),
);
