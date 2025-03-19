import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_login_dto.freezed.dart';
part 'social_login_dto.g.dart';

@freezed
sealed class SocialLoginDto with _$SocialLoginDto {
  factory SocialLoginDto({
    required String code,
    required String lang,
    @Default('default') String flow,
  }) = _SocialLoginDto;

  factory SocialLoginDto.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginDtoFromJson(json);
}
