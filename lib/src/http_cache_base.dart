import 'dart:convert' show json;

import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/request_returns_network_response.dart';

class HttpCache with RequestReturnsNetworkResponse {
  final CachesNetworkRequest storage;
  HttpCacheConfig? httpCacheConfig;

  HttpCache({required this.storage});

  Future<T?> request<T extends CacheItem>(incomingHttpCacheConfig) async {
    httpCacheConfig = incomingHttpCacheConfig;

    if (httpCacheConfig?.networkRequest == null) {
      throw Exception('networkRequest is required');
    }

    if (httpCacheConfig?.ttlDuration == null) {
      return await overwrite();
    }

    return await checkCacheFirst();
  }

  Future<T?> requestFromNetwork<T extends CacheItem>() async {
    NetworkResponse<http.Response, NetworkException> networkResponse =
        await makeRequest<T>(httpCacheConfig!.networkRequest!);

    if (!networkResponse.isSuccessful()) {
      if (kDebugMode) {
        printError(networkResponse.failure!);
      }
      return null;
    }

    Map<String, dynamic> data = httpCacheConfig!.useIsolate
        ? await compute(parseJsonData, networkResponse.success!.body)
        : parseJsonData(networkResponse.success!.body);

    return httpCacheConfig!.fromJson(data);
  }

  void printError(NetworkException failure) {
    if (kDebugMode) {
      if (failure.response == null) {
        print('Error: ${failure.type.name}');
        return;
      }
      print(
          '${failure.type.name}. Error ${failure.response!.statusCode}: ${failure.response!.reasonPhrase}. Message: ${failure.error}');
    }
  }

  static Map<String, dynamic> parseJsonData(String? responseBody) {
    if (responseBody == null) {
      return {};
    }

    final responseData = json.decode(responseBody) as Map<String, dynamic>;

    if (responseData['data'] == null) {
      return {};
    }

    return responseData['data'];
  }

  Future<T?> checkCacheFirst<T extends CacheItem>() async {
    T? cachedValue = await getFromStorage<T>();

    // Cache is available and fresh.
    if (cachedValue == null || _hasCacheExpired(cachedValue)) {
      T? data = await requestFromNetwork();

      if (data != null) {
        await updateCache(data, httpCacheConfig!.cacheKey);
      }

      cachedValue = data;
    }

    return cachedValue;
  }

  Future<T?> overwrite<T extends CacheItem>() async {
    T? data = await requestFromNetwork();

    if (data == null) {
      return null;
    }

    await updateCache<T>(data, httpCacheConfig!.cacheKey);
    return data;
  }

  bool _hasCacheExpired(CacheItem cachedValue) {
    int nowMilliseconds = DateTime.now().millisecondsSinceEpoch;
    int cacheExpiryMilliseconds =
        nowMilliseconds - httpCacheConfig!.ttlDuration!.inMilliseconds;
    bool hasCacheExpired =
        cachedValue.cachedMilliseconds < cacheExpiryMilliseconds;
    return hasCacheExpired;
  }

  Future<void> updateCache<T extends CacheItem>(
      T networkValue, String cacheKey) async {
    networkValue.cachedMilliseconds = DateTime.now().millisecondsSinceEpoch;
    await setStorage(networkValue);
  }

  Future<T?> getFromStorage<T extends CacheItem>() async {
    return await storage.get<T>(httpCacheConfig!.cacheKey);
  }

  Future<void> setStorage<T extends CacheItem>(T networkValue) async {
    await storage.set(httpCacheConfig!.cacheKey, networkValue);
  }
}
