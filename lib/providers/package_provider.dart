import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../models/customer_info.dart';
import 'auth_provider.dart';

final packageInfoProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final token = await SecureStorageService.getToken();
  if (token == null) {
    return HomeData(package: null, customer: CustomerInfo());
  }

  try {
    final apiService = ref.watch(apiServiceProvider);
    return await apiService.getHomeData();
  } catch (_) {
    return HomeData(package: null, customer: CustomerInfo());
  }
});