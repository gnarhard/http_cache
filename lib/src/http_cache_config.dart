import 'package:http/http.dart' as http;

class HttpCacheConfig {
  String cacheKey;
  Duration? ttlDuration;
  Function jsonConverterCallback;
  Future<http.Response> Function()? networkRequest;

  static String ttlCacheKey(String cacheKey) => '${cacheKey}_ttl';

  HttpCacheConfig({
    required this.cacheKey,
    this.ttlDuration,
    required this.networkRequest,
    required this.jsonConverterCallback,
  });
}
