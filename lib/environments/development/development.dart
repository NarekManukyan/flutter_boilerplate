import 'package:json_annotation/json_annotation.dart';

part 'development.g.dart';

@JsonLiteral('development.json', asConst: true)
Map<String, dynamic> get developmentEnv => _$developmentEnvJsonLiteral;
