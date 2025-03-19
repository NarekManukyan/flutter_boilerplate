import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_response_dto.freezed.dart';

part 'user_response_dto.g.dart';

@freezed
sealed class UserResponseDto with _$UserResponseDto {
  factory UserResponseDto({
    required String id,
    required String email,
    required String name,
    @JsonKey(name: 'req_id') required String reqId,
  }) = _UserResponseDto;

  factory UserResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserResponseDtoFromJson(json);
}
