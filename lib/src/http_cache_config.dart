import 'package:http/http.dart' as http;

class HttpCacheConfig {
  final String cacheKey;
  final Duration? ttlDuration;
  final bool useIsolate;
  final Function fromJson;
  final Future<http.Response> Function()? networkRequest;

  HttpCacheConfig({
    required this.cacheKey,
    this.ttlDuration,
    this.useIsolate = false,
    this.networkRequest,
    required this.fromJson,
  });
}
