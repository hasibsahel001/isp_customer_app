import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_info.dart';
import '../services/secure_storage_service.dart';
import 'auth_provider.dart';

// اگر JWT وجود نداشته باشد (یعنی یوزرنیم PPPoE در اکانتینگ پیدا نشده بود)
// یا هر خطای دیگری رخ دهد، به‌جای پرتاب خطا، مقدار null برمی‌گردد
// تا صفحهٔ خانه به‌جای خطای قرمز، پیام ساده «بسته‌ای یافت نشد» نشان دهد
final packageInfoProvider = FutureProvider.autoDispose<PackageInfo?>((ref) async {
  final token = await SecureStorageService.getToken();
  if (token == null) return null;

  try {
    final apiService = ref.watch(apiServiceProvider);
    return await apiService.getPackageInfo();
  } catch (_) {
    return null;
  }
});