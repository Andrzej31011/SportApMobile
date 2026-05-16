import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class TokenStorage {
  TokenStorage(this._secureStorage);

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveToken(String token) {
    return _safeCall(() => _secureStorage.write(key: _tokenKey, value: token));
  }

  Future<String?> readToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> clearToken() {
    return _safeCall(() => _secureStorage.delete(key: _tokenKey));
  }

  Future<void> _safeCall(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException {
      // Ignore secure storage errors in test/offline contexts.
    } on PlatformException {
      // Ignore secure storage errors in test/offline contexts.
    }
  }
}
