import 'package:http/http.dart' as http;
import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/request_returns_network_response.dart';

class HttpCache with RequestReturnsNetworkResponse {
  final CachesNetworkRequest storage;
  HttpCacheConfig? httpCacheConfig;
  final bool hasAsyncStorage;
  bool didNetworkRequest = false;

  NetworkResponse<http.Response, NetworkException>? currentResponse;

  HttpCache({required this.storage, required this.hasAsyncStorage});

  Future<T?> request<T>(HttpCacheConfig incomingHttpCacheConfig) async {
    didNetworkRequest = false;
    currentResponse = null;
    httpCacheConfig = incomingHttpCacheConfig;

    if (httpCacheConfig?.networkRequest == null) {
      throw Exception('networkRequest is required');
    }

    if (httpCacheConfig?.ttlDuration == null) {
      return await overwrite<T>();
    }

    return await checkCacheFirst<T>();
  }

  Future<T?> checkCacheFirst<T>() async {
    T? cachedValue = await getFromStorage<T>();
    final bool cacheExpired = await _hasCacheExpired();

    // Cache is available and fresh.
    if (cachedValue == null || cacheExpired) {
      currentResponse =
          await requestFromNetwork(httpCacheConfig!.networkRequest!);
      didNetworkRequest = true;

      if (!currentResponse!.isSuccessful) {
        return null;
      }

      T? data = await httpCacheConfig!
          .jsonConverterCallback(currentResponse!.success!.body);

      if (data == null) {
        return null;
      }

      await updateCache<T>(data, httpCacheConfig!.cacheKey);

      cachedValue = data;
    }

    return cachedValue;
  }

  Future<T?> overwrite<T>() async {
    currentResponse =
        await requestFromNetwork(httpCacheConfig!.networkRequest!);

    if (!currentResponse!.isSuccessful) {
      return null;
    }

    T? data = await httpCacheConfig!
        .jsonConverterCallback(currentResponse!.success!.body);

    if (data == null) {
      return null;
    }

    await updateCache<T>(data, httpCacheConfig!.cacheKey);
    return data;
  }

  Future<bool> _hasCacheExpired() async {
    int? cachedMilliseconds;

    int cacheExpiryMilliseconds = DateTime.now().millisecondsSinceEpoch -
        httpCacheConfig!.ttlDuration!.inMilliseconds;

    if (hasAsyncStorage) {
      cachedMilliseconds = await storage
          .getAsync(HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey));
    } else {
      cachedMilliseconds =
          storage.get(HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey));
    }

    if (cachedMilliseconds == null) {
      return true;
    }

    return cachedMilliseconds < cacheExpiryMilliseconds;
  }

  Future<void> updateCache<T>(T data, String cacheKey) async {
    final ttl = DateTime.now().millisecondsSinceEpoch;
    await setStorage(data, ttl);
  }

  Future<T?> getFromStorage<T>() async {
    if (hasAsyncStorage) {
      return await storage.getAsync(httpCacheConfig!.cacheKey);
    }
    return storage.get(httpCacheConfig!.cacheKey);
  }

  Future<void> setStorage<T>(T networkValue, int ttl) async {
    if (hasAsyncStorage) {
      await storage.setAsync(httpCacheConfig!.cacheKey, networkValue);
      await storage.setAsync(
          HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey), ttl);
      return;
    }
    storage.set(httpCacheConfig!.cacheKey, networkValue);
    storage.set(HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey), ttl);
  }
}
