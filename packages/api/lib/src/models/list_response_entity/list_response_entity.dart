import 'package:freezed_annotation/freezed_annotation.dart';

import '../../constants/typedefs.dart';

part 'list_response_entity.freezed.dart';
part 'list_response_entity.g.dart';

@freezed
sealed class ListResponseDto<T> with _$ListResponseDto<T> implements Exception {
  const factory ListResponseDto({
    // ignore: inference_failure_on_instance_creation
    @_Converter() required List<T> data,
    MetaDto? meta,
  }) = _ListResponseDto<T>;

  factory ListResponseDto.fromJson(Json json) =>
      _$ListResponseDtoFromJson<T>(json);
}

extension ListResponseDtoExtension<T> on ListResponseDto<T> {
  List<T> parsedData(List<T> old) =>
      meta?.page == 1 ? data : {...old, ...data}.toList();
}

class _Converter<T> implements JsonConverter<T, Json> {
  const _Converter();

  @override
  T fromJson(Json json) {
    switch (T) {
      default:
        throw ArgumentError('add model for type: $T');
    }
  }

  @override
  Json toJson(T object) {
    // This will only work if `object` is a native JSON type:
    //   num, String, bool, null, etc
    // Or if it has a `toJson()` function`.
    // ignore: avoid_dynamic_calls, return_of_invalid_type
    return (object as dynamic)!.toJson();
  }
}

@freezed
sealed class MetaDto with _$MetaDto implements Exception {
  factory MetaDto({
    @Default(10) int take,
    @Default(1) int page,
    @Default(false) bool hasNextPage,
    @Default(false) bool hasPreviousPage,
    @Default(0) int itemCount,
    @Default(0) int pageCount,
  }) = _MetaDto;

  factory MetaDto.fromJson(Json json) => _$MetaDtoFromJson(json);

  MetaDto._();
}
