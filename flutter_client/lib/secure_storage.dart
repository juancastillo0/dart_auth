import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_client.dart';

class SecureStorageClientPersistence extends ClientPersistence {
  ///
  SecureStorageClientPersistence({
    this.storage = const FlutterSecureStorage(),
    this.prefix,
  });
  final FlutterSecureStorage storage;
  final String? prefix;

  String makeKey(String suffix) => prefix == null ? suffix : '$prefix:$suffix';

  @override
  Future<String?> read(String key) => storage.read(key: makeKey(key));
  @override
  Future<void> write(String key, String value) =>
      storage.write(key: makeKey(key), value: value);
  @override
  Future<void> delete(String key) => storage.delete(key: makeKey(key));
}
