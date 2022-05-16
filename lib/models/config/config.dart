import 'package:freezed_annotation/freezed_annotation.dart';

import '../../constants/flavor_type.dart';

part 'config.freezed.dart';
part 'config.g.dart';

@freezed
class Config with _$Config {
  factory Config({
    required Flavor env,
    required bool production,
    required String apiUrl,
  }) = _Config;

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
}
