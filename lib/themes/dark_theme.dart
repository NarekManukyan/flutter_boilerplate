import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_styles.dart';

final base = ThemeData.dark();
const scaffoldBackgroundColor = AppColors.charcoal;

final darkTheme = base.copyWith(
  shadowColor: AppColors.yellow,
  colorScheme: base.colorScheme.copyWith(
    primary: AppColors.charcoal,
    onPrimary: AppColors.white,
  ),
  tabBarTheme: TabBarTheme(
    unselectedLabelStyle: base.primaryTextTheme.button!.copyWith(
      color: AppColors.white,
    ),
    labelStyle: const TextStyle(
      color: AppColors.charcoal,
      fontFamily: FontFamily.CeraPro,
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
  scaffoldBackgroundColor: AppColors.charcoal,
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
    color: AppColors.charcoal,
    centerTitle: true,
    elevation: 0,
    iconTheme: const IconThemeData(
      color: AppColors.white,
    ),
    titleTextStyle: base.primaryTextTheme.headline6!.copyWith(
      fontFamily: FontFamily.CeraPro,
      color: AppColors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      letterSpacing: -.4,
      height: 1.1,
    ),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    toolbarTextStyle: base.textTheme
        .copyWith(
          bodyText1: base.textTheme.bodyText1!.copyWith(
            fontFamily: FontFamily.CeraPro,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          headline6: base.textTheme.headline6!.copyWith(
            fontFamily: FontFamily.CeraPro,
            color: AppColors.chalkboardBlack,
            fontWeight: FontWeight.bold,
          ),
          headline3: base.textTheme.headline3!.copyWith(
            fontFamily: FontFamily.CeraPro,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          headline4: base.textTheme.headline4!.copyWith(
            fontFamily: FontFamily.CeraPro,
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        )
        .bodyText2,
  ),
  bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
    backgroundColor: AppColors.charcoal,
    elevation: 0,
  ),
  chipTheme: base.chipTheme.copyWith(
    backgroundColor: Colors.transparent,
    labelPadding: const EdgeInsets.symmetric(horizontal: 20),
    labelStyle: const TextStyle(
      color: AppColors.white,
      fontWeight: FontWeight.w500,
      fontFamily: FontFamily.CeraPro,
    ),
    selectedColor: AppColors.charcoal,
    secondaryLabelStyle: const TextStyle(
      color: AppColors.charcoal,
      fontWeight: FontWeight.w500,
      fontFamily: FontFamily.CeraPro,
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

  brightness: Brightness.dark,
  inputDecorationTheme: base.inputDecorationTheme.copyWith(
    errorStyle: const TextStyle(
      color: AppColors.red,
      fontFamily: FontFamily.CeraPro,
    ),
    hintStyle: base.primaryTextTheme.bodyText1!.copyWith(
      color: AppColors.grayMedium,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: -.32,
      height: 1.25,
    ),
    fillColor: AppColors.darkTextFillColor,
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
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: -.32,
      height: 1.25,
    ),
  ),
  buttonTheme: base.buttonTheme.copyWith(
    textTheme: ButtonTextTheme.primary,
    buttonColor: AppColors.charcoal,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      textStyle: MaterialStateProperty.resolveWith(
        (states) {
          return states.contains(MaterialState.disabled)
              ? TextStyle(
                  color: AppColors.white.withOpacity(0.4),
                  fontFamily: FontFamily.CeraPro,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.1,
                )
              : const TextStyle(
                  color: AppColors.white,
                  fontFamily: FontFamily.CeraPro,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.1,
                );
        },
      ),
      shape: MaterialStateProperty.resolveWith((state) {
        return const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        );
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? AppColors.burgundy.withOpacity(0.4)
            : AppColors.burgundy;
      }),
      backgroundColor: MaterialStateProperty.resolveWith(
        (states) {
          return states.contains(MaterialState.disabled)
              ? AppColors.grayMedium.withOpacity(0.4)
              : AppColors.grayMedium;
        },
      ),
      overlayColor: MaterialStateProperty.all(
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
      shadowColor: MaterialStateProperty.all(AppColors.yellow),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      elevation: MaterialStateProperty.all(0),
      textStyle: MaterialStateProperty.resolveWith(
        (states) {
          return const TextStyle(
            color: AppColors.white,
            fontFamily: FontFamily.CeraPro,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            height: 1.1,
          );
        },
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      foregroundColor: MaterialStateProperty.all(AppColors.white),
      backgroundColor: MaterialStateProperty.resolveWith(
        (states) {
          return states.contains(MaterialState.disabled)
              ? AppColors.yellow.withOpacity(0.5)
              : AppColors.yellow;
        },
      ),
      overlayColor: MaterialStateProperty.all(
        AppColors.grayMedium.withOpacity(.5),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButtonStyle),
  toggleableActiveColor: AppColors.red,
  textTheme: base.primaryTextTheme.copyWith(
    headline1: base.primaryTextTheme.headline1!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.bold,
      fontSize: 26,
    ),
    headline2: base.primaryTextTheme.headline2!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.bold,
      fontSize: 38,
      letterSpacing: -.76,
      height: 1,
    ),
    headline3: base.primaryTextTheme.headline3!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.bold,
      fontSize: 28,
      letterSpacing: -.56,
      height: 1,
    ),
    headline4: base.primaryTextTheme.headline4!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.normal,
      fontSize: 26,
      letterSpacing: -.52,
      height: 1,
    ),
    headline5: base.primaryTextTheme.headline5!.copyWith(
      fontFamily: FontFamily.CeraPro,
      color: AppColors.white,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      letterSpacing: -.48,
      height: 1.2,
    ),
    headline6: base.primaryTextTheme.headline6!.copyWith(
      fontFamily: FontFamily.CeraPro,
      color: AppColors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      letterSpacing: -.4,
      height: 1.1,
    ),
    subtitle1: base.primaryTextTheme.subtitle1!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      height: 1.25,
      letterSpacing: -.32,
    ),
    subtitle2: base.primaryTextTheme.subtitle2!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.25,
      letterSpacing: -.32,
    ),
    bodyText1: base.primaryTextTheme.bodyText1!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: -.32,
      height: 1.25,
    ),
    bodyText2: base.primaryTextTheme.bodyText2!.copyWith(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.normal,
      fontSize: 14,
      letterSpacing: -.16,
      height: 1.25,
    ),
    caption: const TextStyle(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.normal,
      fontSize: 12,
      height: 1.1,
      letterSpacing: -.16,
    ),
    overline: const TextStyle(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      height: 1.1,
      letterSpacing: -.1,
    ),
    button: const TextStyle(
      color: AppColors.white,
      fontFamily: FontFamily.CeraPro,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      height: 1.1,
    ),
  ),
);
