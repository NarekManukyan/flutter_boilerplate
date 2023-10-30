// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConfigImpl _$$ConfigImplFromJson(Map json) => _$ConfigImpl(
      env: $enumDecode(_$FlavorEnumMap, json['env']),
      production: json['production'] as bool,
      apiUrl: json['apiUrl'] as String,
    );

Map<String, dynamic> _$$ConfigImplToJson(_$ConfigImpl instance) =>
    <String, dynamic>{
      'env': _$FlavorEnumMap[instance.env]!,
      'production': instance.production,
      'apiUrl': instance.apiUrl,
    };

const _$FlavorEnumMap = {
  Flavor.TEST: 'TEST',
  Flavor.DEV: 'DEV',
  Flavor.STAGING: 'STAGING',
  Flavor.PROD: 'PROD',
};
