import 'package:http/http.dart' as http;
import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/request_returns_network_response.dart';

class HttpCache<T> with RequestReturnsNetworkResponse {
  final CachesNetworkRequest storage;
  HttpCacheConfig<T?>? httpCacheConfig;
  final bool hasAsyncStorage;
  bool didNetworkRequest = false;

  NetworkResponse<http.Response, NetworkException>? currentResponse;

  HttpCache({required this.storage, required this.hasAsyncStorage});

  Future<T?> request(HttpCacheConfig<T?> incomingHttpCacheConfig) async {
    didNetworkRequest = false;
    currentResponse = null;
    httpCacheConfig = incomingHttpCacheConfig;

    if (httpCacheConfig?.networkRequest == null) {
      throw Exception('networkRequest is required');
    }

    if (httpCacheConfig?.ttlDuration == null) {
      return await overwrite();
    }

    return await checkCacheFirst();
  }

  Future<T?> checkCacheFirst() async {
    T? cachedValue = await getFromStorage();
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

      await updateCache(data, httpCacheConfig!.cacheKey);

      cachedValue = data;
    }

    return cachedValue;
  }

  Future<T?> overwrite() async {
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

    await updateCache(data, httpCacheConfig!.cacheKey);
    return data;
  }

  Future<bool> _hasCacheExpired() async {
    int? cachedMilliseconds;

    int cacheExpiryMilliseconds = DateTime.now().millisecondsSinceEpoch -
        httpCacheConfig!.ttlDuration!.inMilliseconds;

    if (hasAsyncStorage) {
      cachedMilliseconds = await storage.getAsync<int>(
          HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey));
    } else {
      cachedMilliseconds = storage
          .get<int>(HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey));
    }

    if (cachedMilliseconds == null) {
      return true;
    }

    return cachedMilliseconds < cacheExpiryMilliseconds;
  }

  Future<void> updateCache(T data, String cacheKey) async {
    final ttl = DateTime.now().millisecondsSinceEpoch;
    await setStorage(data, ttl);
  }

  Future<T?> getFromStorage() async {
    if (hasAsyncStorage) {
      return await storage.getAsync<T>(httpCacheConfig!.cacheKey);
    }
    return storage.get<T>(httpCacheConfig!.cacheKey);
  }

  Future<void> setStorage(T networkValue, int ttl) async {
    if (hasAsyncStorage) {
      await storage.setAsync<T>(httpCacheConfig!.cacheKey, networkValue);
      await storage.setAsync<int>(
          HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey), ttl);
      return;
    }
    storage.set<T>(httpCacheConfig!.cacheKey, networkValue);
    storage.set<int>(
        HttpCacheConfig.ttlCacheKey(httpCacheConfig!.cacheKey), ttl);
  }
}
