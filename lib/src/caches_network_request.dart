import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show HttpHeaders, SocketException;

import 'package:http/http.dart' as http;

import 'network_response.dart';

abstract class CachesNetworkRequest {
  Future<T?> get<T>(String key) async {
    return null;
  }

  Future<void> set(String key, dynamic value) async {}
}

mixin RequestReturnsNetworkResponse {
  Future<NetworkResponse<Map<String, dynamic>, NetworkException>>
      makeRequest<Type>(Function request) async {
    try {
      http.Response response = await request();

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData =
            json.decode(response.body) as Map<String, dynamic>;
        return NetworkResponse.success(responseData);
      }

      return NetworkResponse.failure(
          NetworkException(response: response, type: NetworkError.serverError));
    } on SocketException {
      return NetworkResponse.failure(
          const NetworkException(type: NetworkError.couldNotReachServer));
    } on TimeoutException {
      return NetworkResponse.failure(
          const NetworkException(type: NetworkError.couldNotReachServer));
    } catch (error) {
      return NetworkResponse.failure(
          const NetworkException(type: NetworkError.serverError));
    }
  }
}
