import 'package:json_annotation/json_annotation.dart';

part 'test.g.dart';

@JsonLiteral('test.json', asConst: true)
Map<String, dynamic> get testEnv => _$testEnvJsonLiteral;
