import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_create_request_dto.freezed.dart';
part 'todo_create_request_dto.g.dart';

@freezed
sealed class TodoCreateRequestDto with _$TodoCreateRequestDto {
  factory TodoCreateRequestDto({
    required String title,
  }) = _TodoCreateRequestDto;

  factory TodoCreateRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TodoCreateRequestDtoFromJson(json);
}
