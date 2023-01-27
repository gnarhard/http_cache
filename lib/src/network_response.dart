import 'package:http/http.dart';

class NetworkException {
  final Response? response;
  final String? error;
  final NetworkError type;

  const NetworkException({this.response, required this.type, this.error});
}

class NetworkResponse<Success, NetworkException> {
  final Success? success;
  final NetworkException? failure;

  factory NetworkResponse.success(Success success) =>
      NetworkResponse._(success, null);

  factory NetworkResponse.failure(NetworkException failure) =>
      NetworkResponse._(null, failure);

  NetworkResponse._(this.success, this.failure);

  bool isSuccessful() => failure == null;

  Success? result() => success;
}

enum NetworkError {
  noNetworkException,
  couldNotReachServer,
  serverError,
}
