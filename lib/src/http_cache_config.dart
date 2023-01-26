import 'package:http/http.dart' as http;

class HttpCacheConfig {
  String cacheKey;
  Duration? ttlDuration;
  bool useIsolate;
  Function fromJson;
  Future<http.Response> Function()? networkRequest;

  HttpCacheConfig({
    required this.cacheKey,
    this.ttlDuration,
    this.useIsolate = false,
    this.networkRequest,
    required this.fromJson,
  });
}
