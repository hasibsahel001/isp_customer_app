import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _routerUserKey = 'router_username';
  static const _routerPassKey = 'router_password';
  static const _provinceKey = 'selected_province';

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

  static Future<void> saveProvince(String name) async {
    await _storage.write(key: _provinceKey, value: name);
  }

  static Future<String?> getProvince() async {
    return await _storage.read(key: _provinceKey);
  }

  static Future<void> deleteProvince() async {
    await _storage.delete(key: _provinceKey);
  }

  // خروج از حساب: ولایت انتخاب‌شده حفظ می‌شود
  static Future<void> deleteAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _routerUserKey);
    await _storage.delete(key: _routerPassKey);
  }
}