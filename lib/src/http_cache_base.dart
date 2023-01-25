import 'dart:convert' show json;

import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/request_returns_network_response.dart';

class HttpCache<T extends CacheItem> with RequestReturnsNetworkResponse {
  final CachesNetworkRequest storage;
  final String cacheKey;
  final Duration? ttlDuration;
  final bool useIsolate;
  final Function fromJson;
  final Future<http.Response> Function() networkRequest;

  HttpCache(
      {required this.storage,
      required this.cacheKey,
      this.ttlDuration,
      this.useIsolate = false,
      required this.networkRequest,
      required this.fromJson});

  Future<void> updateCache(T networkValue, String cacheKey) async {
    networkValue.cachedMilliseconds = DateTime.now().millisecondsSinceEpoch;
    await storage.set(cacheKey, networkValue);
  }

  Future<T?> request() async {
    if (ttlDuration == null) {
      return await overwrite();
    }

    return await checkCacheFirst();
  }

  Future<T?> requestFromNetwork() async {
    NetworkResponse<http.Response, NetworkException> networkResponse =
        await makeRequest(networkRequest);

    if (!networkResponse.isSuccessful()) {
      if (kDebugMode) {
        printError(networkResponse.failure!);
      }
      return null;
    }

    Map<String, dynamic> data = useIsolate
        ? await compute(parseJsonData, networkResponse.success!.body)
        : parseJsonData(networkResponse.success!.body);

    return fromJson(data);
  }

  void printError(NetworkException failure) {
    if (kDebugMode) {
      print(
          'Error ${failure.response!.statusCode}: ${failure.response!.reasonPhrase}');
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

  Future<T?> checkCacheFirst() async {
    T? cachedValue = await storage.get<T>(cacheKey);

    // Cache is available and fresh.
    if (cachedValue == null || _hasCacheExpired(cachedValue)) {
      T? data = await requestFromNetwork();

      if (data != null) {
        await updateCache(data, cacheKey);
      }

      cachedValue = data;
    }

    return cachedValue;
  }

  Future<T?> overwrite() async {
    T? data = await requestFromNetwork();

    if (data == null) {
      return null;
    }

    await updateCache(data, cacheKey);
    return data;
  }

  bool _hasCacheExpired(CacheItem cachedValue) {
    int nowMilliseconds = DateTime.now().millisecondsSinceEpoch;
    int cacheExpiryMilliseconds = nowMilliseconds - ttlDuration!.inMilliseconds;
    bool hasCacheExpired =
        cachedValue.cachedMilliseconds < cacheExpiryMilliseconds;
    return hasCacheExpired;
  }
}
