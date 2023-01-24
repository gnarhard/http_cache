// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_hive_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MockHiveModel _$MockHiveModelFromJson(Map<String, dynamic> json) =>
    MockHiveModel(
      name: json['name'] as String,
      cachedMilliseconds: json['cachedMilliseconds'] as int? ?? 0,
      id: json['id'] as int,
    );

Map<String, dynamic> _$MockHiveModelToJson(MockHiveModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'cachedMilliseconds': instance.cachedMilliseconds,
    };
