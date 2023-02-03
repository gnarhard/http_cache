import 'package:hive_flutter/adapters.dart';
import 'package:http_cache/http_cache.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Post implements CacheItem {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final int userId;
  @HiveField(2)
  @override
  int cachedMilliseconds;
  @HiveField(3)
  String title;
  @HiveField(4)
  String body;

  Post({
    required this.title,
    required this.body,
    this.cachedMilliseconds = 0,
    required this.id,
    required this.userId,
  });

  Map<String, dynamic> toJson() => _$PostToJson(this);

  factory Post.fromJson(Map<String, dynamic> json) =>
      _$PostFromJson(json);
}
