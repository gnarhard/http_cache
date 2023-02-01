import 'package:flutter/widgets.dart' show Key;
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache/http_cache.dart';
import 'package:http_service/http_service.dart';
import 'package:integration_test/integration_test.dart';
import 'empty_app.dart' as app;
import 'mock_hive_model.dart';
import 'storage_service.dart';

void main() {
  group('HTTP Cache', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    final cacheConfig = HttpCacheConfig(
      cacheKey: 'posts',
      fromJson: MockHiveModel.fromJson,
    );
    late final httpCache = GetIt.I<HttpCache>();
    late final storageService = GetIt.I<StorageService>();
    late final httpService = GetIt.I<HttpService>();

    bool registered = false;

    setUp(() async {
      if (!registered) {
        GetIt.I.registerLazySingleton(() => StorageService(
            adapterRegistrationCallback: () {
              Hive.registerAdapter(MockHiveModelAdapter());
            },
            compactionStrategy: (entries, deletedEntries) =>
                deletedEntries > 3));
        GetIt.I.registerLazySingleton<HttpService>(() => HttpService(
            apiNamespace: '',
            siteBaseUrl: 'https://jsonplaceholder.typicode.com',
            hasConnectivity: () => true,
            getAuthTokenCallback: () => ''));
        GetIt.I.registerLazySingleton<HttpCache>(
            () => HttpCache(storage: storageService));
        registered = true;
      }
    });

    testWidgets("can make POST request and overwrite cache", (tester) async {
      app.main();
      await tester.pumpAndSettle();

      cacheConfig.ttlDuration = null;
      cacheConfig.networkRequest = () async {
        final response = await httpService
            .post(Uri.parse('${httpService.apiUrl}/posts'), body: newUserData);

        return response;
      };

      final networkCache = await httpCache.request(cacheConfig);

      expect(mockHiveModel!.name, 'test');
    });
  });
}
