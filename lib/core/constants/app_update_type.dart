import '../../gen/locale_keys.g.dart';

enum AppUpdateType {
  MINOR,
  MAJOR,
  OPTIONAL;
}

extension AppUpdateTypeExtension on AppUpdateType {
  String get titleTranslationKey => switch (this) {
        AppUpdateType.MINOR =>
          LocaleKeys.enums_appVersionTranslationsTitle_MINOR,
        AppUpdateType.MAJOR =>
          LocaleKeys.enums_appVersionTranslationsTitle_MAJOR,
        _ => '',
      };

  String get subtitleTranslationKey => switch (this) {
        AppUpdateType.MINOR =>
          LocaleKeys.enums_appVersionTranslationsSubtitle_MINOR,
        AppUpdateType.MAJOR =>
          LocaleKeys.enums_appVersionTranslationsSubtitle_MAJOR,
        _ => '',
      };
}
