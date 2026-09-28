import 'package:dio/dio.dart';
import '../models/province.dart';
import '../models/package_info.dart';
import 'secure_storage_service.dart';

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

  Future<PackageInfo> getPackageInfo() async {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      throw Exception('توکن یافت نشد، لطفاً دوباره وارد شوید');
    }

    final response = await _dio.get(
      '/package/info',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return PackageInfo.fromJson(
      response.data['package'] as Map<String, dynamic>,
    );
  }
}