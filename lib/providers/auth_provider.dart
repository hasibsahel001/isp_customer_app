import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;

  AuthState({required this.status});
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkExistingSession();
    return AuthState(status: AuthStatus.unknown);
  }

  // وضعیت ورود حالا بر اساس وجود اطلاعات روتر ذخیره‌شده است، نه JWT بک‌اند
  Future<void> _checkExistingSession() async {
    final creds = await SecureStorageService.getRouterCredentials();
    state = AuthState(
      status: creds != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  // بعد از اتصال موفق به روتر (صرف‌نظر از پیدا شدن یا نشدن بستهٔ اینترنتی)
  void markAuthenticated() {
    state = AuthState(status: AuthStatus.authenticated);
  }

  // تلاش برای گرفتن JWT از بک‌اند؛ اگر ناموفق بود، فقط false برمی‌گرداند
  // و مانع ورود کاربر به اپ نمی‌شود
  Future<bool> tryBackendLogin({
    required String provinceName,
    required String pppoeUsername,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.login(
        provinceName: provinceName,
        pppoeUsername: pppoeUsername,
      );
      final token = result['token'] as String;
      await SecureStorageService.saveToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorageService.deleteAll();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});