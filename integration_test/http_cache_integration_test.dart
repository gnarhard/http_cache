import 'package:flutter/widgets.dart' show Key;
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache/http_cache.dart';
import 'package:http_cache/src/models/post.dart';
import 'package:http_service/http_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http_cache/src/empty_app.dart' as app;
import 'package:http_cache/src/storage_service.dart';

void main() {
  group('HTTP Cache', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    final cacheConfig = HttpCacheConfig(
      cacheKey: 'posts',
      fromJson: Post.fromJson,
    );
    late final httpCache = GetIt.I<HttpCache>();
    late final storageService = GetIt.I<StorageService>();
    late final httpService = GetIt.I<HttpService>();

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
        registered = true;
      }
    });

    // testWidgets("can make POST request and overwrite cache", (tester) async {
    //   await tester.pumpAndSettle();

    //   cacheConfig.ttlDuration = null;
    //   cacheConfig.networkRequest = () async {
    //     final response = await httpService
    //         .post(Uri.parse('${httpService.apiUrl}/posts'), body: newUserData);

    //     return response;
    //   };

    //   final networkCache = await httpCache.request(cacheConfig);

    //   expect(mockHiveModel!.name, 'test');
    // });

    testWidgets("can make GET request and store new cache", (tester) async {
      await tester.pumpAndSettle();

      cacheConfig.ttlDuration = null;
      cacheConfig.networkRequest = () async {
        final response =
            await httpService.get(Uri.parse('${httpService.apiUrl}/posts'));

        return response;
      };

      final networkCache = await httpCache.request<List<Post>>(cacheConfig);

      expect(networkCache, isNotNull);
    });
  });
}
