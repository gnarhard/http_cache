import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:http_cache/http_cache.dart';

class StorageService extends HiveStorageService
    implements CachesNetworkRequest {
  StorageService(
      {required super.adapterRegistrationCallback,
      required super.compactionStrategy});
}
