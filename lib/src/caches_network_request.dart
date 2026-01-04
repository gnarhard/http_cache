abstract class CachesNetworkRequest {
  T? get<T>(String key) {
    return null;
  }

  void set<T>(String key, T value) {}

  Future<T?> getAsync<T>(String key) async {
    return null;
  }

  Future<void> setAsync<T>(String key, dynamic value) async {}
}
