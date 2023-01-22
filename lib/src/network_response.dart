import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class NetworkResponse<Success, Failure> {
  Success? _success;
  Failure? _failure;

  factory NetworkResponse.success(Success success) =>
      NetworkResponse._(success, null);

  factory NetworkResponse.failure(Failure failure) =>
      NetworkResponse._(null, failure);

  NetworkResponse._(this._success, this._failure);

  bool isSuccessful() => _failure == null;

  Success? result() => _success;

  Failure? failure() => _failure;
}

class NetworkException {
  final Response? response;
  final NetworkError type;

  const NetworkException({this.response, required this.type});

  void displayError() {
    String errorMessage =
        "Error ${response!.statusCode}: ${response!.reasonPhrase}";
    if (kDebugMode) {
      print(errorMessage);
    }
    // ToastService.error(message: errorMessage, response: response);
  }
}

enum NetworkError {
  noNetworkException,
  couldNotReachServer,
  serverError,
}
