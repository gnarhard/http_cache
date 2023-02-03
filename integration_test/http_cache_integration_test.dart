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
import 'package:mockito/mockito.dart';

void main() {
  group('HTTP Cache', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    late final httpCache = GetIt.I<HttpCache>();
    late final storageService = GetIt.I<StorageService>();
    late final httpService = GetIt.I<HttpService>();
    final mockHttpCache = MockHttpCache();

    final cacheConfig = HttpCacheConfig(
      cacheKey: 'posts',
      fromJson: Post.fromJson,
    );

    bool registered = false;

    setUp(() async {
      app.main();
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
            () => HttpCache(storage: storageService, asyncStorage: false));

        storageService.openBox(cacheConfig.cacheKey, true);
        storageService.openBox(cacheConfig.ttlCacheKey, false);

        registered = true;
      }
    });

    testWidgets("can make GET requests and store new cache", (tester) async {
      await tester.pumpAndSettle();

      cacheConfig.ttlDuration = null;
      cacheConfig.networkRequest = () async {
        return await httpService.get(Uri.parse('${httpService.apiUrl}/posts'));
      };

      final networkCache = await httpCache.request<List<Post>>(cacheConfig);
      final cachedData = storageService.get(cacheConfig.cacheKey);
      int? ttl = storageService.get<int>(cacheConfig.ttlCacheKey);

      expect(networkCache, isNotNull);
      expect(networkCache!.first.id, 1);
      expect(cachedData, isNotNull);
      expect(ttl! > 0, true);
    });

    testWidgets("can make POST requests and store new cache", (tester) async {
      await tester.pumpAndSettle();

      final newPost = Post.make();

      cacheConfig.ttlDuration = null;
      cacheConfig.networkRequest = () async {
        return await httpService.post(
          Uri.parse('${httpService.apiUrl}/posts'),
          body: newPost,
        );
      };

      final networkCache = await httpCache.request<List<Post>>(cacheConfig);
      final cachedData = storageService.get(cacheConfig.cacheKey);
      int? ttl = storageService.get<int>(cacheConfig.ttlCacheKey);

      expect(networkCache, isNotNull);
      expect(networkCache!.first.id, 1);
      expect(cachedData, isNotNull);
      expect(ttl! > 0, true);
    });

    testWidgets("correctly requests from server when cache is stale",
        (tester) async {
      await tester.pumpAndSettle();

      cacheConfig.ttlDuration = Duration(milliseconds: 1);
      cacheConfig.networkRequest = () async {
        return await httpService.get(Uri.parse('${httpService.apiUrl}/posts'));
      };

      final networkCache = await httpCache.request<List<Post>>(cacheConfig);

      expect(networkCache, isNotNull);
      expect(networkCache!.first.id, 1);

      await tester.pump(Duration(milliseconds: 2));

      cacheConfig.ttlDuration = Duration(milliseconds: 1);
      cacheConfig.networkRequest = () async {
        return await httpService.get(Uri.parse('${httpService.apiUrl}/posts'));
      };

      final newNetworkCache =
          await mockHttpCache.request<List<Post>>(cacheConfig);

      verify(mockHttpCache.requestFromNetwork(cacheConfig.networkRequest));
    });

    testWidgets("correctly requests from storage when cache is fresh",
        (tester) async {
      await tester.pumpAndSettle();

      cacheConfig.ttlDuration = Duration(seconds: 1);
      cacheConfig.networkRequest = () async {
        return await httpService.get(Uri.parse('${httpService.apiUrl}/posts'));
      };

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

      final newNetworkCache =
          await mockHttpCache.request<List<Post>>(cacheConfig);

      verify(mockHttpCache.requestFromNetwork(cacheConfig.networkRequest));
    });
  });
}
