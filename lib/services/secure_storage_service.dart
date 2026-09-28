import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _routerUserKey = 'router_username';
  static const _routerPassKey = 'router_password';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveRouterCredentials(String username, String password) async {
    await _storage.write(key: _routerUserKey, value: username);
    await _storage.write(key: _routerPassKey, value: password);
  }

  static Future<Map<String, String>?> getRouterCredentials() async {
    final u = await _storage.read(key: _routerUserKey);
    final p = await _storage.read(key: _routerPassKey);
    if (u == null || p == null) return null;
    return {'username': u, 'password': p};
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}