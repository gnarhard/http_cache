abstract class CachesNetworkRequest {
  T? get<T>(String key) {
    return null;
  }

  void set(String key, dynamic value) {}

  Future<T?> getAsync<T>(String key) async {
    return null;
  }

  Future<void> setAsync(String key, dynamic value) async {}
}
