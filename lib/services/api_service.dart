import 'package:dio/dio.dart';
import '../models/province.dart';
import '../models/package_info.dart';
import '../models/customer_info.dart';
import 'secure_storage_service.dart';

class HomeData {
  final PackageInfo? package;
  final CustomerInfo customer;

  HomeData({required this.package, required this.customer});
}

class ApiService {
  static const String baseUrl = 'https://ispco-api.duckdns.org';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<Province>> getProvinces() async {
    final response = await _dio.get('/provinces');
    final List<dynamic> list = response.data['provinces'];
    return list.map((e) => Province.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> login({
    required String provinceName,
    required String pppoeUsername,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'provinceName': provinceName,
        'pppoeUsername': pppoeUsername,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<HomeData> getHomeData() async {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      throw Exception('توکن یافت نشد، لطفاً دوباره وارد شوید');
    }

    final response = await _dio.get(
      '/package/info',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data as Map<String, dynamic>;
    final packageJson = data['package'] as Map<String, dynamic>?;

    return HomeData(
      package: (packageJson != null && packageJson['error'] == null)
          ? PackageInfo.fromJson(packageJson)
          : null,
      customer: CustomerInfo.fromJson(data['customer'] as Map<String, dynamic>?),
    );
  }
}