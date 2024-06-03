// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element, unnecessary_cast

part of 'theme_colors.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$CustomThemeTailorMixin on ThemeExtension<CustomTheme> {
  Color get background;

  @override
  CustomTheme copyWith({
    Color? background,
  }) {
    return CustomTheme(
      background: background ?? this.background,
    );
  }

  @override
  CustomTheme lerp(covariant ThemeExtension<CustomTheme>? other, double t) {
    if (other is! CustomTheme) return this as CustomTheme;
    return CustomTheme(
      background: Color.lerp(background, other.background, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CustomTheme &&
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

extension CustomThemeBuildContextProps on BuildContext {
  CustomTheme get customTheme => Theme.of(this).extension<CustomTheme>()!;
  Color get background => customTheme.background;
}
