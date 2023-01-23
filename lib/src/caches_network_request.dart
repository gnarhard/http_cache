abstract class CachesNetworkRequest {
  Future<T?> get<T>(String key) async {
    return null;
  }

  Future<void> set(String key, dynamic value) async {}
}
