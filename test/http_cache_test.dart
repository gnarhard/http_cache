import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:http_cache/http_cache.dart';
import 'package:http_service/http_service.dart';
import 'package:test/test.dart';

import '../secrets.dart';
import 'mock_hive_model.dart';
import 'storage_service.dart';

void main() {
  group('A group of tests', () {
    final storageService = StorageService(adapterRegistrationCallback: () {
      // Hive.registerAdapter(MockHiveModelAdapter());
    });
    final http = HttpService(
        apiNamespace: '/api/v1',
        apiUrl: 'https://example.com/api/v1',
        publicImgPath: 'https://example.com/images',
        siteBaseUrl: 'https://example.com',
        hasConnectivity: () => true,
        getAuthTokenCallback: () => token);

    setUp(() async {
      // MockStorageService.useMockStorage();
      await storageService.wipe();
    });
    tearDown(() async => await storageService.wipe());

    test('Can login and retrieve token.', () async {
      final httpCache = HttpCache<MockHiveModel>(storage: storageService);
      final cacheKey = 'mock_hive_model';
      storageService.cacheKeys.add(cacheKey);
      storageService.init();
      final mockHiveModel = MockHiveModel(
        id: 1,
        name: 'Test',
      );

      http.client = MockClient((request) async {
        final mapJson = {
          "code": 200,
          "message": null,
          "data": mockHiveModel,
        };
        return Response(json.encode(mapJson), 200);
      });

      MockHiveModel? cachedMock = await httpCache.request(
        cacheKey: cacheKey,
        networkRequest: () => http.get(Uri.parse('${http.apiUrl}/getMock')),
        fromJson: MockHiveModel.fromJson,
      );

      expect(cachedMock!.id, 1);
    });
  });
}
