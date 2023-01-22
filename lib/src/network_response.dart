import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class NetworkResponse<S, F> {
  S? _s;
  F? _f;

  factory NetworkResponse.success(S s) => NetworkResponse._(s, null);

  factory NetworkResponse.failure(F f) => NetworkResponse._(null, f);

  NetworkResponse._(this._s, this._f);

  bool isSuccessful() => _f == null;

  S? result() => _s;

  F? failure() => _f;
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
