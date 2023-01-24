import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart';

class NetworkResponse<Success, NetworkException> {
  Success? _success;
  NetworkException? _failure;

  factory NetworkResponse.success(Success success) =>
      NetworkResponse._(success, null);

  factory NetworkResponse.failure(NetworkException failure) =>
      NetworkResponse._(null, failure);

  NetworkResponse._(this._success, this._failure);

  bool isSuccessful() => _failure == null;

  Success? result() => _success;

  NetworkException? failure() => _failure;

  void printError() {
    // String errorMessage =
    //     "Error ${_failure!.response.statusCode}: ${_failure!.response.reasonPhrase}";

    if (kDebugMode) {
      print(_failure);
    }
  }
}

class NetworkException {
  final Response? response;
  final dynamic error;
  final NetworkError type;

  const NetworkException({this.response, required this.type, this.error});
}

enum NetworkError {
  noNetworkException,
  couldNotReachServer,
  serverError,
}
