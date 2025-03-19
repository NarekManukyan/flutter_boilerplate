import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response_dto.freezed.dart';

part 'auth_response_dto.g.dart';

@freezed
sealed class AuthResponseDto with _$AuthResponseDto {
  factory AuthResponseDto({
    required String token,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}
