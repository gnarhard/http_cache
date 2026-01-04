import 'dart:convert';
import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:faker/faker.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  final int id;
  final int userId;
  String title;
  String body;

  Post({
    required this.title,
    required this.body,
    required this.id,
    required this.userId,
  });

  Map<String, dynamic> toJson() => _$PostToJson(this);

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  static List<Post> fromJsonString(String jsonString) {
    final decodedData = json.decode(jsonString);
    final convertedData = <Post>[];

    if (decodedData is Map<String, dynamic>) {
      return decodedData.entries.map((e) => Post.fromJson(e.value)).toList();
    }

    for (Map<String, dynamic> singleData in decodedData) {
      convertedData.add(Post.fromJson(singleData));
    }

    return convertedData;
  }

  factory Post.make() {
    Faker faker = Faker();
    Random random = Random();
    return Post(
      id: random.nextInt(50) + 1000,
      userId: random.nextInt(5) + 1000,
      body: faker.lorem.sentences(random.nextInt(10)).toString(),
      title: faker.lorem.words(random.nextInt(3)).toString(),
    );
  }
}
