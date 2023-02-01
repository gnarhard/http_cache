import 'dart:math';

import 'package:faker/faker.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http_cache/http_cache.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mock_hive_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class MockHiveModel implements CacheItem {
  @HiveField(0)
  final int id;
  @HiveField(1)
  String name;
  @HiveField(2)
  @override
  int cachedMilliseconds;

  MockHiveModel({
    required this.name,
    this.cachedMilliseconds = 0,
    required this.id,
  });

  Map<String, dynamic> toJson() => _$MockHiveModelToJson(this);

  factory MockHiveModel.fromJson(Map<String, dynamic> json) =>
      _$MockHiveModelFromJson(json);

  factory MockHiveModel.fake() {
    Faker faker = Faker();
    Random random = Random();
    return MockHiveModel(
      name: faker.person.name(),
      id: random.nextInt(100),
    );
  }
}
