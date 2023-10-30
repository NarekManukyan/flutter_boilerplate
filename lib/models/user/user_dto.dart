import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';

part 'user_dto.g.dart';

@freezed
class UserDto with _$UserDto {
  UserDto._();

  factory UserDto({
    String? email,
    String? id,
    String? firstName,
    String? lastName,
  }) = _UserDto;

  late final fullName = '$firstName $lastName';

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}
