import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'network_response.dart';

mixin RequestReturnsNetworkResponse {
  Future<NetworkResponse<http.Response, NetworkException>> makeRequest<Type>(
      Future<http.Response> Function() request) async {
    try {
      http.Response response = await request();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse.success(response);
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
          NetworkException(type: NetworkError.serverError, error: error));
    }
  }
}
