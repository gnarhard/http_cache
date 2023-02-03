import 'dart:math';

import 'package:hive_flutter/adapters.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Post {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final int userId;
  @HiveField(2)
  String title;
  @HiveField(3)
  String body;

  Post({
    required this.title,
    required this.body,
    required this.id,
    required this.userId,
  });

  Map<String, dynamic> toJson() => _$PostToJson(this);

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  factory Post.make() {
    Faker faker = Faker();
    Random random = Random();
    return Post(
      id: random.nextInt(50) + 1000,
      userId: random.nextInt(5) + 1000,
      body: faker.sentence(),
      title: faker.sentence(),
    );
  }
}
