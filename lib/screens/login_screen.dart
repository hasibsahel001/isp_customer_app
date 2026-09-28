import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province.dart';
import '../providers/auth_provider.dart';
import '../services/router_service.dart';
import '../services/wifi_helper.dart';
import '../services/secure_storage_service.dart';
import '../config/router_config.dart' as app_config;
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

// ============================================
// 🧪 TEST MODE — فقط برای توسعه، قبل از انتشار نهایی این خط را false کنید
const bool kEnableTestLoginBypass = true;
// ============================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  List<Province> _provinces = [];
  Province? _selectedProvince;
  bool _isLoadingProvinces = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final provinces = await apiService.getProvinces();
      setState(() {
        _provinces = provinces;
        _selectedProvince = provinces.isNotEmpty ? provinces.first : null;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProvinces = false;
        _errorMessage = 'خطا در دریافت لیست ولایت‌ها. اتصال اینترنت را بررسی کنید.';
      });
    }
  }

  // فقط برای خطاهای واقعی اتصال به روتر (این تنها خطاهایی هستند که مانع ورود می‌شوند)
  String _friendlyErrorMessage(Object error) {
    final raw = error.toString().replaceAll('Exception: ', '');

    if (raw.contains('invalid user name or password') ||
        raw.contains('cannot log in')) {
      return 'یوزرنیم یا پسورد اشتباه است';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Connection refused') ||
        raw.contains('Connection timed out') ||
        raw.contains('پاسخی از روتر دریافت نشد')) {
      return 'اتصال به روتر برقرار نشد. مطمئن شوید به وای‌فای روتر خود وصل هستید';
    }
    if (raw.contains('دسترسی به اطلاعات وای‌فای لازم است')) {
      return 'برای ورود، لطفاً دسترسی موقعیت مکانی را برای برنامه فعال کنید';
    }
    if (raw.contains('لطفاً ابتدا به وای‌فای روتر خودتان وصل شوید')) {
      return 'لطفاً ابتدا به وای‌فای روتر خودتان وصل شوید';
    }
    if (raw.contains('آدرس روتر یافت نشد')) {
      return 'آدرس روتر پیدا نشد. اتصال وای‌فای را بررسی کنید';
    }

    return 'ورود ناموفق بود. لطفاً دوباره تلاش کنید یا با پشتیبانی تماس بگیرید';
  }

  Future<void> _handleLogin() async {
    if (_selectedProvince == null) {
      setState(() => _errorMessage = 'لطفاً ولایت خود را انتخاب کنید');
      return;
    }
    final routerUsername = _usernameController.text.trim();
    final routerPassword = _passwordController.text.trim();
    if (routerUsername.isEmpty || routerPassword.isEmpty) {
      setState(() => _errorMessage = 'لطفاً یوزرنیم و پسورد را وارد کنید');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    RouterService? routerService;

    try {
      final hasPermission = await WifiHelper.requestPermission();
      if (!hasPermission) {
        throw Exception('برای ورود، دسترسی به اطلاعات وای‌فای لازم است');
      }

      final isWifi = await WifiHelper.isConnectedToWifi();
      if (!isWifi) {
        throw Exception('لطفاً ابتدا به وای‌فای روتر خودتان وصل شوید');
      }

      final gatewayIp = await WifiHelper.getGatewayIp();
      if (gatewayIp == null) {
        throw Exception('آدرس روتر یافت نشد');
      }

      // این تنها بخشی است که در صورت شکست، ورود را کاملاً متوقف می‌کند
      routerService = RouterService();
      await routerService.connect(
        gatewayIp,
        app_config.RouterConfig.apiPort,
        routerUsername,
        routerPassword,
      );

      // اتصال به روتر موفق بود؛ از این به بعد کاربر قطعاً وارد اپ می‌شود
      await SecureStorageService.saveRouterCredentials(routerUsername, routerPassword);

      // تلاش برای یافتن یوزرنیم PPPoE و اطلاعات بسته — کاملاً اختیاری
      try {
        final pppoeUsername = await routerService.getPppoeUsername();
        if (pppoeUsername != null) {
          await ref.read(authProvider.notifier).tryBackendLogin(
            provinceName: _selectedProvince!.name,
            pppoeUsername: pppoeUsername,
          );
        }
      } catch (_) {
        // اگر PPPoE یا بک‌اند مشکل داشت، نادیده می‌گیریم؛ تب خانه بعداً "بدون بسته" نشان می‌دهد
      }

      ref.read(authProvider.notifier).markAuthenticated();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyErrorMessage(e);
      });
    } finally {
      await routerService?.close();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 🧪 TEST MODE: ورود مستقیم با یک یوزرنیم دلخواه، بدون اتصال به روتر
  Future<void> _handleTestLogin() async {
    final testUsernameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ورود آزمایشی (بدون روتر)'),
          content: TextField(
            controller: testUsernameController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'یوزرنیم PPPoE واقعی',
              hintText: 'مثلاً MatinHome',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, testUsernameController.text.trim()),
              child: const Text('ورود'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty || _selectedProvince == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    await ref.read(authProvider.notifier).tryBackendLogin(
      provinceName: _selectedProvince!.name,
      pppoeUsername: result,
    );

    // در حالت تست هم فقط اتصال (فرضی) را authenticated می‌کنیم
    await SecureStorageService.saveRouterCredentials('test', 'test');
    ref.read(authProvider.notifier).markAuthenticated();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildLogo(),
                const SizedBox(height: 28),
                const Text(
                  'خوش آمدید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'برای مشاهدهٔ وضعیت بستهٔ اینترنتی خود وارد شوید',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 42),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLoadingProvinces)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          else
            DropdownButtonFormField<Province>(
              initialValue: _selectedProvince,
              decoration: const InputDecoration(
                labelText: 'ولایت',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
              items: _provinces.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedProvince = value);
              },
            ),

          const SizedBox(height: 14),

          TextField(
            controller: _usernameController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'یوزرنیم',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'پسورد',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleLogin,
            child: _isSubmitting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.2,
              ),
            )
                : const Text('ورود'),
          ),

          // 🧪 TEST MODE — این بلوک را قبل از انتشار نهایی حذف کنید
          if (kEnableTestLoginBypass) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSubmitting ? null : _handleTestLogin,
              child: const Text(
                '🧪 ورود آزمایشی (بدون اتصال به روتر)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}