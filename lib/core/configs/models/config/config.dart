import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../constants/flavor_type.dart';

part 'config.freezed.dart';

part 'config.g.dart';

@freezed
sealed class Config with _$Config {
  factory Config({
    required FlavorType env,
    required bool production,
    required String apiUrl,
    required String socketUrl,
    required String bundleID,
    required ReCaptchaConfig reCaptcha,
    required MicrosoftConfig microsoft,
    required GoogleConfig google,
    required String sentryDsn,
  }) = _Config;

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
}

@freezed
sealed class MicrosoftConfig with _$MicrosoftConfig {
  factory MicrosoftConfig({
    required String authUrl,
    required String connectUrl,
    required String host,
  }) = _MicrosoftConfig;

  factory MicrosoftConfig.fromJson(Map<String, dynamic> json) =>
      _$MicrosoftConfigFromJson(json);
}

@freezed
sealed class GoogleConfig with _$GoogleConfig {
  factory GoogleConfig({required String serverClientId}) = _GoogleConfig;

  factory GoogleConfig.fromJson(Map<String, dynamic> json) =>
      _$GoogleConfigFromJson(json);
}

@freezed
sealed class ReCaptchaConfig with _$ReCaptchaConfig {
  factory ReCaptchaConfig({
    required String androidKey,
    required String iosKey,
  }) = _ReCaptchaConfig;

  factory ReCaptchaConfig.fromJson(Map<String, dynamic> json) =>
      _$ReCaptchaConfigFromJson(json);
}
