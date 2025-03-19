import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'custom_theme.tailor.dart';

@tailorMixin
class CustomTheme extends ThemeExtension<CustomTheme>
    with _$CustomThemeTailorMixin {
  CustomTheme({
    required this.backgroundSurface,
    required this.backgroundSurfaceTransparent,
    required this.backgroundPrimaryDefault,
    required this.backgroundPrimaryHover,
    required this.backgroundPrimaryPressed,
    required this.backgroundDisabled,
    required this.backgroundPrimaryDefaultLighter,
    required this.backgroundDisabledDarker,
    required this.backgroundSecondaryDefault,
    required this.backgroundPrimaryHoverLighter,
    required this.backgroundSecondaryHover,
    required this.backgroundPrimaryPressedLighter,
    required this.backgroundNeutralDefault,
    required this.backgroundSecondaryPressed,
    required this.backgroundSelectedDefaultLighter,
    required this.backgroundNeutralHover,
    required this.backgroundSecondaryDefaultLighter,
    required this.backgroundNeutralPressed,
    required this.backgroundSelectedHoverLighter,
    required this.backgroundSecondaryHoverLighter,
    required this.backgroundNeutralDefaultLighter,
    required this.backgroundSelectedPressedLighter,
    required this.backgroundSecondaryPressedLighter,
    required this.backgroundNeutralHoverLighter,
    required this.backgroundSelectedDefault,
    required this.backgroundNeutralPressedLighter,
    required this.backgroundSelectedHover,
    required this.backgroundNeutralDefaultDark,
    required this.backgroundSelectedPressed,
    required this.backgroundNeutralHoverDark,
    required this.backgroundDangerDefaultLighter,
    required this.backgroundDangerHoverLighter,
    required this.backgroundNeutralPressedDark,
    required this.backgroundNeutralDefaultDarker,
    required this.backgroundDangerPressedLighter,
    required this.backgroundNeutralHoverDarker,
    required this.backgroundDangerDefault,
    required this.backgroundDangerHover,
    required this.backgroundNeutralPressedDarker,
    required this.backgroundDangerPressed,
    required this.backgroundDangerDefaultDarker,
    required this.backgroundDangerHoverDarker,
    required this.backgroundDangerPressedDarker,
    required this.backgroundSuccessDefault,
    required this.backgroundSuccessHover,
    required this.backgroundSuccessPressed,
    required this.backgroundSuccessDefaultDarker,
    required this.backgroundSuccessHoverDarker,
    required this.backgroundSuccessPressedDarker,
    required this.backgroundWarningDefault,
    required this.backgroundWarningHover,
    required this.backgroundWarningPressed,
    required this.backgroundWarningDefaultDarker,
    required this.backgroundWarningHoverDarker,
    required this.backgroundWarningPressedDarker,
    required this.backgroundInformationDefault,
    required this.backgroundInformationHover,
    required this.backgroundInformationPressed,
    required this.backgroundInformationDefaultDarker,
    required this.backgroundInformationHoverDarker,
    required this.backgroundInformationPressedDarker,
    required this.backgroundAccentPurpleLighter,
    required this.backgroundAccentPurpleLight,
    required this.backgroundAccentPurpleDefault,
    required this.backgroundAccentPurpleDark,
    required this.backgroundAccentPurpleDarker,
    required this.backgroundAccentOrangeLighter,
    required this.backgroundAccentOrangeDarker,
    required this.backgroundAccentGreenLighter,
    required this.backgroundAccentGreen,
    required this.backgroundAccentGreenDarker,
    required this.backgroundAccentRedLighter,
    required this.backgroundAccentRedDarker,
    required this.backgroundAccentYellowLighter,
    required this.backgroundAccentYellowDarker,
    required this.backgroundAccentMerinoLighter,
    required this.backgroundAccentMerinoDarker,
    required this.backgroundAccentNeutralLighter,
    required this.backgroundAccentNeutralLight,
    required this.backgroundAccentNeutralDark,
    required this.backgroundAccentNeutralDarker,
    required this.backgroundAccentBlueLighter,
    required this.backgroundAccentBlue,
    required this.backgroundAccentBlueDarker,
    required this.textPrimary,
    required this.textPrimaryDark,
    required this.textPrimaryDarker,
    required this.textSecondary,
    required this.textSecondaryDarker,
    required this.textNeutralDarker,
    required this.textNeutral,
    required this.textNeutralLighter,
    required this.textDisabled,
    required this.textInverse,
    required this.textInverseDark,
    required this.textSelected,
    required this.textDanger,
    required this.textDangerLighter,
    required this.textWarning,
    required this.textWarningLighter,
    required this.textSuccess,
    required this.textSuccessLighter,
    required this.textInformation,
    required this.textInformationLighter,
    required this.linkPrimary,
    required this.linkPrimaryHover,
    required this.linkPrimaryPressed,
    required this.linkInformationLight,
    required this.linkInformationLightHover,
    required this.linkInformationLightPressed,
    required this.linkNeutral,
    required this.linkNeutralHover,
    required this.linkNeutralPressed,
    required this.linkNeutralLight,
    required this.linkNeutralLightHover,
    required this.linkNeutralLightPressed,
    required this.linkInverse,
    required this.linkInverseHover,
    required this.linkInversePressed,
    required this.linkDisabled,
    required this.iconPrimary,
    required this.iconPrimaryDark,
    required this.iconPrimaryDarker,
    required this.iconSecondary,
    required this.iconSecondaryDarker,
    required this.iconNeutral,
    required this.iconNeutralLighter,
    required this.iconNeutralDarker,
    required this.iconInverse,
    required this.iconInverseDarker,
    required this.iconDisabled,
    required this.iconSelected,
    required this.iconDanger,
    required this.iconDangerLighter,
    required this.iconWarning,
    required this.iconWarningLighter,
    required this.iconSuccess,
    required this.iconSuccessLighter,
    required this.iconInformation,
    required this.iconInformationLighter,
    required this.iconAccentMerino,
    required this.iconAccentNeutral,
    required this.borderPrimary,
    required this.borderPrimaryDarker,
    required this.borderSecondary,
    required this.borderSecondaryDarker,
    required this.borderNeutralLight,
    required this.borderNeutralLighter,
    required this.borderNeutral,
    required this.borderNeutralDarker,
    required this.borderDisabled,
    required this.borderInverse,
    required this.borderFocus,
    required this.borderSelected,
    required this.borderDanger,
    required this.borderDangerLighter,
    required this.borderWarning,
    required this.borderWarningLighter,
    required this.borderSuccess,
    required this.borderSuccessLighter,
    required this.borderInformation,
    required this.borderInformationLighter,
    required this.borderAccentMerino,
    required this.borderAccentNeutral,
    required this.borderAccentNeutralDark,
    required this.borderAccentNeutralDarker,
    required this.blanketDefault,
    required this.overlayLow,
    required this.overlayMedium,
    required this.overlayHigh,
    required this.overlayDefault,
    required this.headerH1,
    required this.headerH2,
    required this.headerH3,
    required this.headerH4,
    required this.headerH5,
    required this.subheaderS1Bold,
    required this.subheaderS1Medium,
    required this.subheaderS2Bold,
    required this.subheaderS2Medium,
    required this.paragraphNotesBold,
    required this.paragraphNotesSemibold,
    required this.paragraphNotesMedium,
    required this.paragraphNotesRegular,
    required this.paragraphXLBold,
    required this.paragraphXLSemibold,
    required this.paragraphXLMedium,
    required this.paragraphXLRegular,
    required this.paragraphLBold,
    required this.paragraphLSemibold,
    required this.paragraphLMedium,
    required this.paragraphLRegular,
    required this.paragraphMBold,
    required this.paragraphMSemibold,
    required this.paragraphMMedium,
    required this.paragraphMRegular,
    required this.paragraphSBold,
    required this.paragraphSSemibold,
    required this.paragraphSMedium,
    required this.paragraphSRegular,
    required this.labelXXLBold,
    required this.labelXXLSemibold,
    required this.labelXXLMedium,
    required this.labelXXLRegular,
    required this.labelXLBold,
    required this.labelXLSemibold,
    required this.labelXLMedium,
    required this.labelXLRegular,
    required this.labelLBold,
    required this.labelLSemibold,
    required this.labelLMedium,
    required this.labelLRegular,
    required this.labelMBold,
    required this.labelMSemibold,
    required this.labelMMedium,
    required this.labelMRegular,
    required this.labelSBold,
    required this.labelSSemibold,
    required this.labelSMedium,
    required this.labelSRegular,
    required this.labelXSBold,
    required this.labelXSSemibold,
    required this.labelXSMedium,
    required this.labelXSRegular,
    required this.labelUnderlineXLSemibold,
    required this.labelUnderlineXLMedium,
    required this.labelUnderlineXLRegular,
    required this.labelUnderlineLSemibold,
    required this.labelUnderlineLMedium,
    required this.labelUnderlineLRegular,
    required this.labelUnderlineMSemibold,
    required this.labelUnderlineMMedium,
    required this.labelUnderlineMRegular,
    required this.labelUnderlineSSemibold,
    required this.labelUnderlineSMedium,
    required this.labelUnderlineSRegular,
    required this.listingBold,
  });

  @override
  Color backgroundSurface;
  @override
  Color backgroundSurfaceTransparent;
  @override
  Color backgroundPrimaryDefault;
  @override
  Color backgroundPrimaryHover;
  @override
  Color backgroundPrimaryPressed;
  @override
  Color backgroundDisabled;
  @override
  Color backgroundPrimaryDefaultLighter;
  @override
  Color backgroundDisabledDarker;
  @override
  Color backgroundSecondaryDefault;
  @override
  Color backgroundPrimaryHoverLighter;
  @override
  Color backgroundSecondaryHover;
  @override
  Color backgroundPrimaryPressedLighter;
  @override
  Color backgroundNeutralDefault;
  @override
  Color backgroundSecondaryPressed;
  @override
  Color backgroundSelectedDefaultLighter;
  @override
  Color backgroundNeutralHover;
  @override
  Color backgroundSecondaryDefaultLighter;
  @override
  Color backgroundNeutralPressed;
  @override
  Color backgroundSelectedHoverLighter;
  @override
  Color backgroundSecondaryHoverLighter;
  @override
  Color backgroundNeutralDefaultLighter;
  @override
  Color backgroundSelectedPressedLighter;
  @override
  Color backgroundSecondaryPressedLighter;
  @override
  Color backgroundNeutralHoverLighter;
  @override
  Color backgroundSelectedDefault;
  @override
  Color backgroundNeutralPressedLighter;
  @override
  Color backgroundSelectedHover;
  @override
  Color backgroundNeutralDefaultDark;
  @override
  Color backgroundSelectedPressed;
  @override
  Color backgroundNeutralHoverDark;
  @override
  Color backgroundDangerDefaultLighter;
  @override
  Color backgroundDangerHoverLighter;
  @override
  Color backgroundNeutralPressedDark;
  @override
  Color backgroundNeutralDefaultDarker;
  @override
  Color backgroundDangerPressedLighter;
  @override
  Color backgroundNeutralHoverDarker;
  @override
  Color backgroundDangerDefault;
  @override
  Color backgroundDangerHover;
  @override
  Color backgroundNeutralPressedDarker;
  @override
  Color backgroundDangerPressed;
  @override
  Color backgroundDangerDefaultDarker;
  @override
  Color backgroundDangerHoverDarker;
  @override
  Color backgroundDangerPressedDarker;
  @override
  Color backgroundSuccessDefault;
  @override
  Color backgroundSuccessHover;
  @override
  Color backgroundSuccessPressed;
  @override
  Color backgroundSuccessDefaultDarker;
  @override
  Color backgroundSuccessHoverDarker;
  @override
  Color backgroundSuccessPressedDarker;
  @override
  Color backgroundWarningDefault;
  @override
  Color backgroundWarningHover;
  @override
  Color backgroundWarningPressed;
  @override
  Color backgroundWarningDefaultDarker;
  @override
  Color backgroundWarningHoverDarker;
  @override
  Color backgroundWarningPressedDarker;
  @override
  Color backgroundInformationDefault;
  @override
  Color backgroundInformationHover;
  @override
  Color backgroundInformationPressed;
  @override
  Color backgroundInformationDefaultDarker;
  @override
  Color backgroundInformationHoverDarker;
  @override
  Color backgroundInformationPressedDarker;
  @override
  Color backgroundAccentPurpleLighter;
  @override
  Color backgroundAccentPurpleLight;
  @override
  Color backgroundAccentPurpleDefault;
  @override
  Color backgroundAccentPurpleDark;
  @override
  Color backgroundAccentPurpleDarker;
  @override
  Color backgroundAccentOrangeLighter;
  @override
  Color backgroundAccentOrangeDarker;
  @override
  Color backgroundAccentGreenLighter;
  @override
  Color backgroundAccentGreen;
  @override
  Color backgroundAccentGreenDarker;
  @override
  Color backgroundAccentRedLighter;
  @override
  Color backgroundAccentRedDarker;
  @override
  Color backgroundAccentYellowLighter;
  @override
  Color backgroundAccentYellowDarker;
  @override
  Color backgroundAccentMerinoLighter;
  @override
  Color backgroundAccentMerinoDarker;
  @override
  Color backgroundAccentNeutralLighter;
  @override
  Color backgroundAccentNeutralLight;
  @override
  Color backgroundAccentNeutralDark;
  @override
  Color backgroundAccentNeutralDarker;
  @override
  Color backgroundAccentBlueLighter;
  @override
  Color backgroundAccentBlue;
  @override
  Color backgroundAccentBlueDarker;
  @override
  Color textPrimary;
  @override
  Color textPrimaryDark;
  @override
  Color textPrimaryDarker;
  @override
  Color textSecondary;
  @override
  Color textSecondaryDarker;
  @override
  Color textNeutralDarker;
  @override
  Color textNeutral;
  @override
  Color textNeutralLighter;
  @override
  Color textDisabled;
  @override
  Color textInverse;
  @override
  Color textInverseDark;
  @override
  Color textSelected;
  @override
  Color textDanger;
  @override
  Color textDangerLighter;
  @override
  Color textWarning;
  @override
  Color textWarningLighter;
  @override
  Color textSuccess;
  @override
  Color textSuccessLighter;
  @override
  Color textInformation;
  @override
  Color textInformationLighter;
  @override
  Color linkPrimary;
  @override
  Color linkPrimaryHover;
  @override
  Color linkPrimaryPressed;
  @override
  Color linkInformationLight;
  @override
  Color linkInformationLightHover;
  @override
  Color linkInformationLightPressed;
  @override
  Color linkNeutral;
  @override
  Color linkNeutralHover;
  @override
  Color linkNeutralPressed;
  @override
  Color linkNeutralLight;
  @override
  Color linkNeutralLightHover;
  @override
  Color linkNeutralLightPressed;
  @override
  Color linkInverse;
  @override
  Color linkInverseHover;
  @override
  Color linkInversePressed;
  @override
  Color linkDisabled;
  @override
  Color iconPrimary;
  @override
  Color iconPrimaryDark;
  @override
  Color iconPrimaryDarker;
  @override
  Color iconSecondary;
  @override
  Color iconSecondaryDarker;
  @override
  Color iconNeutral;
  @override
  Color iconNeutralLighter;
  @override
  Color iconNeutralDarker;
  @override
  Color iconInverse;
  @override
  Color iconInverseDarker;
  @override
  Color iconDisabled;
  @override
  Color iconSelected;
  @override
  Color iconDanger;
  @override
  Color iconDangerLighter;
  @override
  Color iconWarning;
  @override
  Color iconWarningLighter;
  @override
  Color iconSuccess;
  @override
  Color iconSuccessLighter;
  @override
  Color iconInformation;
  @override
  Color iconInformationLighter;
  @override
  Color iconAccentMerino;
  @override
  Color iconAccentNeutral;
  @override
  Color borderPrimary;
  @override
  Color borderPrimaryDarker;
  @override
  Color borderSecondary;
  @override
  Color borderSecondaryDarker;
  @override
  Color borderNeutralLight;
  @override
  Color borderNeutralLighter;
  @override
  Color borderNeutral;
  @override
  Color borderNeutralDarker;
  @override
  Color borderDisabled;
  @override
  Color borderInverse;
  @override
  Color borderFocus;
  @override
  Color borderSelected;
  @override
  Color borderDanger;
  @override
  Color borderDangerLighter;
  @override
  Color borderWarning;
  @override
  Color borderWarningLighter;
  @override
  Color borderSuccess;
  @override
  Color borderSuccessLighter;
  @override
  Color borderInformation;
  @override
  Color borderInformationLighter;
  @override
  Color borderAccentMerino;
  @override
  Color borderAccentNeutral;
  @override
  Color borderAccentNeutralDark;
  @override
  Color borderAccentNeutralDarker;
  @override
  Color blanketDefault;
  @override
  Color overlayLow;
  @override
  Color overlayMedium;
  @override
  Color overlayHigh;
  @override
  Color overlayDefault;
  @override
  TextStyle headerH1;
  @override
  TextStyle headerH2;
  @override
  TextStyle headerH3;
  @override
  TextStyle headerH4;
  @override
  TextStyle headerH5;
  @override
  TextStyle subheaderS1Bold;
  @override
  TextStyle subheaderS1Medium;
  @override
  TextStyle subheaderS2Bold;
  @override
  TextStyle subheaderS2Medium;
  @override
  TextStyle paragraphNotesBold;
  @override
  TextStyle paragraphNotesSemibold;
  @override
  TextStyle paragraphNotesMedium;
  @override
  TextStyle paragraphNotesRegular;
  @override
  TextStyle paragraphXLBold;
  @override
  TextStyle paragraphXLSemibold;
  @override
  TextStyle paragraphXLMedium;
  @override
  TextStyle paragraphXLRegular;
  @override
  TextStyle paragraphLBold;
  @override
  TextStyle paragraphLSemibold;
  @override
  TextStyle paragraphLMedium;
  @override
  TextStyle paragraphLRegular;
  @override
  TextStyle paragraphMBold;
  @override
  TextStyle paragraphMSemibold;
  @override
  TextStyle paragraphMMedium;
  @override
  TextStyle paragraphMRegular;
  @override
  TextStyle paragraphSBold;
  @override
  TextStyle paragraphSSemibold;
  @override
  TextStyle paragraphSMedium;
  @override
  TextStyle paragraphSRegular;
  @override
  TextStyle labelXXLBold;
  @override
  TextStyle labelXXLSemibold;
  @override
  TextStyle labelXXLMedium;
  @override
  TextStyle labelXXLRegular;
  @override
  TextStyle labelXLBold;
  @override
  TextStyle labelXLSemibold;
  @override
  TextStyle labelXLMedium;
  @override
  TextStyle labelXLRegular;
  @override
  TextStyle labelLBold;
  @override
  TextStyle labelLSemibold;
  @override
  TextStyle labelLMedium;
  @override
  TextStyle labelLRegular;
  @override
  TextStyle labelMBold;
  @override
  TextStyle labelMSemibold;
  @override
  TextStyle labelMMedium;
  @override
  TextStyle labelMRegular;
  @override
  TextStyle labelSBold;
  @override
  TextStyle labelSSemibold;
  @override
  TextStyle labelSMedium;
  @override
  TextStyle labelSRegular;
  @override
  TextStyle labelXSBold;
  @override
  TextStyle labelXSSemibold;
  @override
  TextStyle labelXSMedium;
  @override
  TextStyle labelXSRegular;
  @override
  TextStyle labelUnderlineXLSemibold;
  @override
  TextStyle labelUnderlineXLMedium;
  @override
  TextStyle labelUnderlineXLRegular;
  @override
  TextStyle labelUnderlineLSemibold;
  @override
  TextStyle labelUnderlineLMedium;
  @override
  TextStyle labelUnderlineLRegular;
  @override
  TextStyle labelUnderlineMSemibold;
  @override
  TextStyle labelUnderlineMMedium;
  @override
  TextStyle labelUnderlineMRegular;
  @override
  TextStyle labelUnderlineSSemibold;
  @override
  TextStyle labelUnderlineSMedium;
  @override
  TextStyle labelUnderlineSRegular;
  @override
  TextStyle listingBold;
}
