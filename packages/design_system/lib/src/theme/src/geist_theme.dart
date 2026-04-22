import 'package:flutter/material.dart';

/// Vercel/Geist-inspired design system. Achromatic surfaces, shadow-as-border,
/// compressed typography. Consume via `context.geist`.
///
/// Add new Geist tokens here — never hardcode colors/styles in the app layer.
@immutable
class GeistTheme extends ThemeExtension<GeistTheme> {
  const GeistTheme({
    required this.surface,
    required this.ink,
    required this.muted,
    required this.subtle,
    required this.placeholder,
    required this.hairline,
    required this.ringSoft,
    required this.innerGlow,
    required this.focusBlue,
    required this.badgeInfoBg,
    required this.badgeInfoFg,
    required this.badgeSuccessBg,
    required this.badgeSuccessFg,
    required this.danger,
    required this.warn,
    required this.elevation,
    required this.ambient,
    required this.fabShadow,
    required this.focusHaloAlpha,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  // Core
  final Color surface; // page / card background
  final Color ink; // primary text + primary CTA bg
  final Color muted; // secondary text
  final Color subtle; // tertiary / helper text
  final Color placeholder; // hint text / disabled

  // Border / depth
  final Color hairline; // primary shadow-as-border stroke
  final Color ringSoft; // lighter ring for tabs, images
  final Color innerGlow; // inner highlight layer in card stack

  // Interactive
  final Color focusBlue;
  final double focusHaloAlpha;

  // Status pills
  final Color badgeInfoBg;
  final Color badgeInfoFg;
  final Color badgeSuccessBg;
  final Color badgeSuccessFg;

  // Semantic
  final Color danger;
  final Color warn;

  // Shadows (elevation color only; offsets/blur encoded in helpers)
  final Color elevation; // soft card lift
  final Color ambient; // diffuse depth at distance
  final Color fabShadow;

  // Skeleton shimmer
  final Color skeletonBase;
  final Color skeletonHighlight;

  // -------- Derived helpers --------

  BoxShadow get shadowBorder => BoxShadow(color: hairline, spreadRadius: 1);
  BoxShadow get shadowRingSoft => BoxShadow(color: ringSoft, spreadRadius: 1);
  BoxShadow get shadowInnerGlow => BoxShadow(color: innerGlow, spreadRadius: 1);

  BoxShadow get shadowElevation =>
      BoxShadow(color: elevation, offset: const Offset(0, 2), blurRadius: 2);

  BoxShadow get shadowAmbient => BoxShadow(
    color: ambient,
    offset: const Offset(0, 8),
    blurRadius: 8,
    spreadRadius: -8,
  );

  BoxShadow get shadowFab => BoxShadow(
    color: fabShadow,
    offset: const Offset(0, 8),
    blurRadius: 20,
    spreadRadius: -8,
  );

  /// Full Vercel card stack: hairline + elevation + ambient + inner glow.
  List<BoxShadow> get cardShadow => [
    shadowBorder,
    shadowElevation,
    shadowAmbient,
    shadowInnerGlow,
  ];

  /// Minimal ring: hairline + inner glow only.
  List<BoxShadow> get ringShadow => [shadowBorder, shadowInnerGlow];

  // -------- Theme variants --------

  static const GeistTheme light = GeistTheme(
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF171717),
    muted: Color(0xFF4D4D4D),
    subtle: Color(0xFF666666),
    placeholder: Color(0xFF808080),
    hairline: Color(0x14000000), // rgba(0,0,0,0.08)
    ringSoft: Color(0xFFEBEBEB),
    innerGlow: Color(0xFFFAFAFA),
    focusBlue: Color(0xFF0A72EF),
    focusHaloAlpha: 0.12,
    badgeInfoBg: Color(0xFFEBF5FF),
    badgeInfoFg: Color(0xFF0068D6),
    badgeSuccessBg: Color(0xFFE6F6EC),
    badgeSuccessFg: Color(0xFF1A7F37),
    danger: Color(0xFFDC2626),
    warn: Color(0xFFB25B00),
    elevation: Color(0x0A000000),
    ambient: Color(0x0A000000),
    fabShadow: Color(0x33000000),
    skeletonBase: Color(0xFFF5F5F5),
    skeletonHighlight: Color(0xFFEDEDED),
  );

  /// Dark mode: inverted with desaturated tonal variants per DESIGN.md.
  /// Not a pure inversion — surface #0A0A0A, ink #EDEDED, hairline uses alpha on white.
  static const GeistTheme dark = GeistTheme(
    surface: Color(0xFF0A0A0A),
    ink: Color(0xFFEDEDED),
    muted: Color(0xFFA1A1A1),
    subtle: Color(0xFF8F8F8F),
    placeholder: Color(0xFF6E6E6E),
    hairline: Color(0x1AFFFFFF), // rgba(255,255,255,0.10)
    ringSoft: Color(0xFF262626),
    innerGlow: Color(0xFF141414),
    focusBlue: Color(0xFF47A3FF),
    focusHaloAlpha: 0.22,
    badgeInfoBg: Color(0xFF0D2A4A),
    badgeInfoFg: Color(0xFF8FC4FF),
    badgeSuccessBg: Color(0xFF0F2E1B),
    badgeSuccessFg: Color(0xFF7FD69A),
    danger: Color(0xFFFF6B6B),
    warn: Color(0xFFFFB668),
    elevation: Color(0x33000000),
    ambient: Color(0x4D000000),
    fabShadow: Color(0x66000000),
    skeletonBase: Color(0xFF1A1A1A),
    skeletonHighlight: Color(0xFF242424),
  );

  @override
  GeistTheme copyWith({
    Color? surface,
    Color? ink,
    Color? muted,
    Color? subtle,
    Color? placeholder,
    Color? hairline,
    Color? ringSoft,
    Color? innerGlow,
    Color? focusBlue,
    double? focusHaloAlpha,
    Color? badgeInfoBg,
    Color? badgeInfoFg,
    Color? badgeSuccessBg,
    Color? badgeSuccessFg,
    Color? danger,
    Color? warn,
    Color? elevation,
    Color? ambient,
    Color? fabShadow,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return GeistTheme(
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      subtle: subtle ?? this.subtle,
      placeholder: placeholder ?? this.placeholder,
      hairline: hairline ?? this.hairline,
      ringSoft: ringSoft ?? this.ringSoft,
      innerGlow: innerGlow ?? this.innerGlow,
      focusBlue: focusBlue ?? this.focusBlue,
      focusHaloAlpha: focusHaloAlpha ?? this.focusHaloAlpha,
      badgeInfoBg: badgeInfoBg ?? this.badgeInfoBg,
      badgeInfoFg: badgeInfoFg ?? this.badgeInfoFg,
      badgeSuccessBg: badgeSuccessBg ?? this.badgeSuccessBg,
      badgeSuccessFg: badgeSuccessFg ?? this.badgeSuccessFg,
      danger: danger ?? this.danger,
      warn: warn ?? this.warn,
      elevation: elevation ?? this.elevation,
      ambient: ambient ?? this.ambient,
      fabShadow: fabShadow ?? this.fabShadow,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  GeistTheme lerp(covariant GeistTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return GeistTheme(
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      ringSoft: Color.lerp(ringSoft, other.ringSoft, t)!,
      innerGlow: Color.lerp(innerGlow, other.innerGlow, t)!,
      focusBlue: Color.lerp(focusBlue, other.focusBlue, t)!,
      focusHaloAlpha: _lerpD(focusHaloAlpha, other.focusHaloAlpha, t),
      badgeInfoBg: Color.lerp(badgeInfoBg, other.badgeInfoBg, t)!,
      badgeInfoFg: Color.lerp(badgeInfoFg, other.badgeInfoFg, t)!,
      badgeSuccessBg: Color.lerp(badgeSuccessBg, other.badgeSuccessBg, t)!,
      badgeSuccessFg: Color.lerp(badgeSuccessFg, other.badgeSuccessFg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      elevation: Color.lerp(elevation, other.elevation, t)!,
      ambient: Color.lerp(ambient, other.ambient, t)!,
      fabShadow: Color.lerp(fabShadow, other.fabShadow, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(
        skeletonHighlight,
        other.skeletonHighlight,
        t,
      )!,
    );
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;
}

extension GeistThemeX on BuildContext {
  GeistTheme get geist =>
      Theme.of(this).extension<GeistTheme>() ?? GeistTheme.light;
}

/// Compressed Geist typography. All weights ≤ 600; tight negative tracking at display.
/// Add new text styles here — never hardcode TextStyle in app layer.
class GeistTextStyles {
  GeistTextStyles._();

  // Display — billboard hero (40-48 px, aggressive -1.6 to -2.4 tracking).
  static const displayXL = TextStyle(
    fontSize: 48,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: -2.4,
  );
  static const displayL = TextStyle(
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.6,
  );
  static const displayM = TextStyle(
    fontSize: 36,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.6,
  );

  // Heading
  static const heading = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.12,
  );
  static const subheading = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.8,
  );
  static const cardTitle = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.96,
  );

  // Nav / strong label
  static const navTitle = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.32,
  );
  static const sectionTitle = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
  );

  // Body
  static const bodyL = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const bodyM = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const bodyS = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const bodyXS = TextStyle(
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  // List row primary text
  static const listRow = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.24,
  );

  // Buttons / interactive labels
  static const button = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );
  static const buttonLarge = TextStyle(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );

  // Chip label
  static const chip = TextStyle(
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );
  static const chipCount = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  // Status / pill badge
  static const badge = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  // Mono micro-label (uppercase technical labels).
  static const monoLabel = TextStyle(
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    fontFamily: 'monospace',
  );
  static const monoLabelTight = TextStyle(
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    fontFamily: 'monospace',
  );

  // Mono numeric counter with tabular figures.
  static const monoCounter = TextStyle(
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Error / helper
  static const helperError = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );
}

/// Geist border radius scale.
class GeistRadius {
  GeistRadius._();
  static const double micro = 2;
  static const double subtle = 4;
  static const double standard = 6;
  static const double comfortable = 8;
  static const double image = 12;
  static const double pill = 999;
}

/// Motion duration tokens.
class GeistDuration {
  GeistDuration._();
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const breathe = Duration(milliseconds: 2400);
}
