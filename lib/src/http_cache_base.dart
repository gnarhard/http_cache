import 'dart:convert' show json;

import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/request_returns_network_response.dart';

class HttpCache with RequestReturnsNetworkResponse {
  final CachesNetworkRequest storage;
  HttpCacheConfig? httpCacheConfig;
  final bool asyncStorage;

  String get ttlCacheKey => '${httpCacheConfig!.cacheKey}_ttl';

  NetworkResponse<http.Response, NetworkException>? currentResponse;

  HttpCache({required this.storage, required this.asyncStorage});

  Future<T?> request<T>(incomingHttpCacheConfig) async {
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

      if (!currentResponse!.isSuccessful) {
        return null;
      }

      T? data = await convert<T>(currentResponse!.success!.body);

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

    T? data = await convert<T>(currentResponse!.success!.body);

    if (data == null) {
      return null;
    }

    await updateCache<T>(data, httpCacheConfig!.cacheKey);
    return data;
  }

  Future<bool> _hasCacheExpired() async {
    late final int cachedMilliseconds;

    int cacheExpiryMilliseconds = DateTime.now().millisecondsSinceEpoch -
        httpCacheConfig!.ttlDuration!.inMilliseconds;

    if (asyncStorage) {
      cachedMilliseconds = await storage.getAsync(ttlCacheKey);
    } else {
      cachedMilliseconds = storage.get(ttlCacheKey);
    }

    return cachedMilliseconds < cacheExpiryMilliseconds;
  }

  Future<void> updateCache<T>(T data, String cacheKey) async {
    final ttl = DateTime.now().millisecondsSinceEpoch;
    await setStorage(data, ttl);
  }

  Future<T?> getFromStorage<T>() async {
    if (asyncStorage) {
      return await storage.getAsync(httpCacheConfig!.cacheKey);
    }
    return storage.get(httpCacheConfig!.cacheKey);
  }

  Future<void> setStorage<T>(T networkValue, int ttl) async {
    if (asyncStorage) {
      await storage.setAsync(httpCacheConfig!.cacheKey, networkValue);
      await storage.setAsync(ttlCacheKey, ttl);
      return;
    }
    storage.set(httpCacheConfig!.cacheKey, networkValue);
    storage.set(ttlCacheKey, ttl);
  }

  Future<T?> convert<T>(String responseBody) async {
    final data = httpCacheConfig!.useIsolate
        ? await compute(parseJsonData, responseBody)
        : parseJsonData(currentResponse!.success!.body);

    if (data is List) {
      final convertedData = [];
      for (Map<String, dynamic> singleData in data) {
        convertedData.add(httpCacheConfig!.fromJson(singleData));
      }
      return convertedData as T;
    }

    return data as T;
  }

  /// Decodes JSON into either a list of maps or a single map.
  static parseJsonData(String? responseBody) {
    if (responseBody == null) {
      return {};
    }

    final responseData = json.decode(responseBody) as Map<String, dynamic>;

    if (responseData['data'] == null) {
      return {};
    }

    return responseData['data'] is List
        ? responseData['data']
        : responseData['data'];
  }
}
