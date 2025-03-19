import 'package:json_annotation/json_annotation.dart';

part 'production.g.dart';

@JsonLiteral('production.json', asConst: true)
Map<String, dynamic> get productionEnv => _$productionEnvJsonLiteral;
