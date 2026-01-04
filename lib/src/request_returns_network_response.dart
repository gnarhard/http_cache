import 'dart:async' show TimeoutException;
import 'dart:convert' show json;
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:http/http.dart' as http;

import '../http_cache.dart';

mixin RequestReturnsNetworkResponse {
  Future<NetworkResponse<http.Response, NetworkException>> requestFromNetwork(
      Future<http.Response> Function() request) async {
    final networkResponse = await makeRequest(request);

    if (!networkResponse.isSuccessful) {
      if (kDebugMode) {
        printError(networkResponse.failure!);
      }
    }

    return networkResponse;
  }

  Future<NetworkResponse<http.Response, NetworkException>> makeRequest(
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
      return NetworkResponse.failure(NetworkException(
          type: NetworkError.serverError, error: error.toString()));
    }
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
}
