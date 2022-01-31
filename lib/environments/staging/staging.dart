import 'package:json_annotation/json_annotation.dart';

part 'staging.g.dart';

@JsonLiteral('staging.json', asConst: true)
Map<String, dynamic> get stagingEnv => _$stagingEnvJsonLiteral;
