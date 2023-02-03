import 'package:http/http.dart' as http;

class HttpCacheConfig {
  String cacheKey;
  Duration? ttlDuration;
  bool useIsolate;
  Function fromJson;
  Future<http.Response> Function()? networkRequest;

  String get ttlCacheKey => '${cacheKey}_ttl';

  HttpCacheConfig({
    required this.cacheKey,
    this.ttlDuration,
    this.useIsolate = false,
    this.networkRequest,
    required this.fromJson,
  });
}
