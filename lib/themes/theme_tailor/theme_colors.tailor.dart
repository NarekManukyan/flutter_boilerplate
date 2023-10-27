// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element, unnecessary_cast

part of 'theme_colors.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

class ThemeColors extends ThemeExtension<ThemeColors> {
  const ThemeColors({
    required this.background,
  });

  final Color background;

  static const ThemeColors light = ThemeColors(
    background: AppColors.blackHeadlines,
  );

  static const ThemeColors dark = ThemeColors(
    background: AppColors.gray,
  );

  static const themes = [
    light,
    dark,
  ];

  @override
  ThemeColors copyWith({
    Color? background,
  }) {
    return ThemeColors(
      background: background ?? this.background,
    );
  }

  @override
  ThemeColors lerp(covariant ThemeExtension<ThemeColors>? other, double t) {
    if (other is! ThemeColors) return this as ThemeColors;
    return ThemeColors(
      background: Color.lerp(background, other.background, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ThemeColors &&
            const DeepCollectionEquality()
                .equals(background, other.background));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(background),
    );
  }
}

extension ThemeColorsBuildContextProps on BuildContext {
  ThemeColors get themeColors => Theme.of(this).extension<ThemeColors>()!;
  Color get background => themeColors.background;
}
