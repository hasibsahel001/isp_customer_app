import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

enum AuthStage { unknown, needProvince, needLogin, authenticated }

class AuthState {
  final AuthStage stage;
  final Province? province;

  AuthState({required this.stage, this.province});
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return AuthState(stage: AuthStage.unknown);
  }

  Future<void> _init() async {
    final provinceName = await SecureStorageService.getProvince();
    if (provinceName == null) {
      state = AuthState(stage: AuthStage.needProvince);
      return;
    }

    Province? province;
    try {
      final list = await ref.read(apiServiceProvider).getProvinces();
      for (final p in list) {
        if (p.name == provinceName) province = p;
      }
    } catch (_) {}
    province ??= Province(id: 0, name: provinceName, displayName: provinceName);

    final creds = await SecureStorageService.getRouterCredentials();
    if (creds != null) {
      state = AuthState(stage: AuthStage.authenticated, province: province);
    } else {
      state = AuthState(stage: AuthStage.needLogin, province: province);
    }
  }

  Future<void> selectProvince(Province p) async {
    await SecureStorageService.saveProvince(p.name);
    state = AuthState(stage: AuthStage.needLogin, province: p);
  }

  Future<void> changeProvince() async {
    await SecureStorageService.deleteProvince();
    state = AuthState(stage: AuthStage.needProvince);
  }

  void markAuthenticated() {
    state = AuthState(stage: AuthStage.authenticated, province: state.province);
  }

  // حالا در صورت خطا، آن را پرتاب می‌کند تا فراخوان تصمیم بگیرد چه کند
  Future<void> tryBackendLogin({
    required String provinceName,
    required String pppoeUsername,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    final result = await apiService.login(
      provinceName: provinceName,
      pppoeUsername: pppoeUsername,
    );
    final token = result['token'] as String;
    await SecureStorageService.saveToken(token);
  }

  Future<void> logout() async {
    await SecureStorageService.deleteAll();
    state = AuthState(stage: AuthStage.needLogin, province: state.province);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});