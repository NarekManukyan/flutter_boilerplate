import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_sign_in_dto.freezed.dart';

part 'social_sign_in_dto.g.dart';

@freezed
sealed class SocialSignInDto with _$SocialSignInDto {
  const factory SocialSignInDto({
    required String flow,
    required String code,
    required String lang,
    @Default(false) bool? fromMobile,
  }) = _SocialSignInDto;

  factory SocialSignInDto.fromJson(Map<String, dynamic> json) =>
      _$SocialSignInDtoFromJson(json);
}
