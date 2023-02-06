import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/models/post.dart';
import 'package:http_service/http_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http_cache/src/empty_app.dart' as app;
import 'package:http_cache/src/storage_service.dart';
import 'package:http_cache/src/http_cache_base.mocks.dart';

void main() {
  group('HTTP Cache', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    late final httpCache = GetIt.I<HttpCache>();
    late final storageService = GetIt.I<StorageService>();
    late final httpService = GetIt.I<HttpService>();
    bool registered = false;
    const String cacheKey = 'posts';

    setUp(() async {
      if (!registered) {
        GetIt.I.registerLazySingleton(() => StorageService(
            adapterRegistrationCallback: () {
              Hive.registerAdapter(PostAdapter());
            },
            compactionStrategy: (entries, deletedEntries) =>
                deletedEntries > 3));
        GetIt.I.registerLazySingleton<HttpService>(() => HttpService(
            apiNamespace: '',
            siteBaseUrl: 'https://jsonplaceholder.typicode.com',
            hasConnectivity: () => true,
            getAuthTokenCallback: () => ''));
        GetIt.I.registerLazySingleton<HttpCache>(
            () => HttpCache(storage: storageService, hasAsyncStorage: false));

        await storageService.init();
        storageService.openBox(cacheKey, true);
        storageService.openBox(HttpCacheConfig.ttlCacheKey(cacheKey), false);

        registered = true;
      }

      app.main();
    });

    tearDown(() => storageService.destroy(cacheKey));

    testWidgets("can get data from server and store in cache", (tester) async {
      await tester.pumpAndSettle();

      final cacheConfig = HttpCacheConfig(
        cacheKey: cacheKey,
        ttlDuration: null,
        networkRequest: () async {
          return await httpService
              .get(Uri.parse('${httpService.apiUrl}/posts'));
        },
        jsonConverterCallback: (jsonString) {
          if (jsonString == null) {
            return null;
          }
          return Post.fromJsonString<List<Post>>(jsonString);
        },
      );

      final networkCache = await httpCache.request<List<Post>>(cacheConfig);
      final cachedData = storageService.get(cacheConfig.cacheKey);
      int? ttl = storageService.get<int>(HttpCacheConfig.ttlCacheKey(cacheKey));

      expect(networkCache, isNotNull);
      expect(networkCache!.first.id, 1);
      expect(cachedData, isNotNull);
      expect(ttl! > 0, true);
    });

    testWidgets("correctly requests from server when cache is stale",
        (tester) async {
      await tester.pumpAndSettle();

      final cacheConfig = HttpCacheConfig(
        cacheKey: cacheKey,
        ttlDuration: const Duration(milliseconds: 1),
        networkRequest: () async {
          return await httpService
              .get(Uri.parse('${httpService.apiUrl}/posts'));
        },
        jsonConverterCallback: (jsonString) {
          if (jsonString == null) {
            return null;
          }
          return Post.fromJsonString<List<Post>>(jsonString);
        },
      );

      final networkCache = await httpCache.request<List<Post>>(cacheConfig);

      expect(networkCache, isNotNull);
      expect(networkCache!.first.id, 1);

      await tester.pump(Duration(milliseconds: 2));

      final newNetworkCache = await httpCache.request<List<Post>>(cacheConfig);

      expect(httpCache.didNetworkRequest, true);
    });

    testWidgets("correctly requests from storage when cache is fresh",
        (tester) async {
      await tester.pumpAndSettle();

      final cacheConfig = HttpCacheConfig(
        cacheKey: cacheKey,
        ttlDuration: const Duration(seconds: 1),
        networkRequest: () async {
          return await httpService
              .get(Uri.parse('${httpService.apiUrl}/posts'));
        },
        jsonConverterCallback: (jsonString) {
          if (jsonString == null) {
            return null;
          }
          return Post.fromJsonString<List<Post>>(jsonString);
        },
      );

      final networkCache = await httpCache.request<List<Post>>(cacheConfig);

      expect(networkCache, isNotNull);
      expect(networkCache!.first.id, 1);

      await tester.pump(Duration(milliseconds: 20));

      cacheConfig.ttlDuration = Duration(seconds: 1);
      cacheConfig.networkRequest = () async {
        return await httpService.get(Uri.parse('${httpService.apiUrl}/posts'));
      };

      cacheConfig.networkRequest = () async {
        return await httpService.get(Uri.parse('${httpService.apiUrl}/posts'));
      };

      final newNetworkCache = await httpCache.request<List<Post>>(cacheConfig);

      expect(httpCache.didNetworkRequest, false);
    });
  });
}
