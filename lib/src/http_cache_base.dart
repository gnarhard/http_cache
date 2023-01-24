import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/request_returns_network_response.dart';

class HttpCache<T extends CacheItem> with RequestReturnsNetworkResponse {
  final CachesNetworkRequest storage;

  HttpCache({required this.storage});

  Future<void> updateCache<Type>(T networkValue, String cacheKey) async {
    networkValue.cachedMilliseconds = DateTime.now().millisecondsSinceEpoch;
    await storage.set(cacheKey, networkValue);
  }

  Future<T?> request(
      {required String cacheKey,
      required Function networkRequest,
      Duration? ttlDuration,
      required Function fromJson}) async {
    if (ttlDuration == null) {
      return await checkCacheFirst(
          networkRequest, cacheKey, ttlDuration!, fromJson);
    }

    return await overwrite(networkRequest, cacheKey, fromJson);
  }

  Future<T?> requestFromNetwork(
      Function networkRequest, Function fromJson) async {
    NetworkResponse response = await makeRequest(networkRequest);

    if (!response.isSuccessful()) {
      return null;
    }

    T data = fromJson(response.result());
    return data;
  }

  Future<T?> checkCacheFirst(Function networkRequest, String cacheKey,
      Duration ttlDuration, Function fromJson) async {
    T? cachedValue = await storage.get(cacheKey);

    // Cache is available and fresh.
    if (cachedValue == null || _hasCacheExpired(cachedValue, ttlDuration)) {
      T? data = await requestFromNetwork(networkRequest, fromJson);

      if (data != null) {
        await updateCache(data, cacheKey);
      }

      cachedValue = data;
    }

    return cachedValue;
  }

  Future<T?> overwrite(
      Function networkRequest, String cacheKey, Function fromJson) async {
    T? data = await requestFromNetwork(networkRequest, fromJson);

    if (data == null) {
      return null;
    }

    await updateCache(data, cacheKey);
    return data;
  }

  bool _hasCacheExpired(CacheItem cachedValue, Duration ttlDuration) {
    int nowMilliseconds = DateTime.now().millisecondsSinceEpoch;
    int cacheExpiryMilliseconds = nowMilliseconds - ttlDuration.inMilliseconds;
    bool hasCacheExpired =
        cachedValue.cachedMilliseconds < cacheExpiryMilliseconds;
    return hasCacheExpired;
  }
}
