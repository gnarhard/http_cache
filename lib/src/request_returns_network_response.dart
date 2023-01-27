import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../http_cache.dart';

mixin RequestReturnsNetworkResponse {
  Future<NetworkResponse<http.Response, NetworkException>>
      makeRequest<Type extends CacheItem>(
          Future<http.Response> Function() request) async {
    try {
      http.Response response = await request();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse.success(response);
      }

      final responseBody = json.decode(response.body);
      String errorMessage = '';

      if (responseBody['message'] != null) {
        errorMessage = responseBody['message'];
      }

      return NetworkResponse.failure(NetworkException(
          response: response,
          type: NetworkError.serverError,
          error: errorMessage));
    } on SocketException {
      return NetworkResponse.failure(
          const NetworkException(type: NetworkError.couldNotReachServer));
    } on TimeoutException {
      return NetworkResponse.failure(
          const NetworkException(type: NetworkError.couldNotReachServer));
    } catch (error) {
      return NetworkResponse.failure(
          NetworkException(type: NetworkError.serverError, error: error.toString()));
    }
  }
}
