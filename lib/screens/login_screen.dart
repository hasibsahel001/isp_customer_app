import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/router_config.dart' as app_config;
import '../config/support_contacts.dart';
import '../models/province.dart';
import '../providers/auth_provider.dart';
import '../services/router_service.dart';
import '../services/secure_storage_service.dart';
import '../services/wifi_helper.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'province_select_screen.dart';

// 🧪 TEST MODE — قبل از انتشار نهایی false شود
const bool kEnableTestLoginBypass = true;

class LoginScreen extends ConsumerStatefulWidget {
  final Province province;
  const LoginScreen({super.key, required this.province});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  String _friendlyErrorMessage(Object error) {
    final raw = error.toString().replaceAll('Exception: ', '');

    if (raw.contains('invalid user name or password') || raw.contains('cannot log in')) {
      return 'آیدی کاربری اشتباه است';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Connection refused') ||
        raw.contains('timed out') ||
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
    final userId = _idController.text.trim();
    if (userId.isEmpty) {
      setState(() => _errorMessage = 'لطفاً آیدی کاربری خود را وارد کنید');
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
      if (!await WifiHelper.isConnectedToWifi()) {
        throw Exception('لطفاً ابتدا به وای‌فای روتر خودتان وصل شوید');
      }
      final gatewayIp = await WifiHelper.getGatewayIp();
      if (gatewayIp == null) throw Exception('آدرس روتر یافت نشد');

      // آیدی کاربری هم یوزر و هم پسورد روتر است
      routerService = RouterService();
      await routerService.connect(
        gatewayIp,
        app_config.RouterConfig.apiPort,
        userId,
        userId,
      );

      await SecureStorageService.saveRouterCredentials(userId, userId);

      // اختیاری: یافتن PPPoE و بستهٔ اینترنتی
      try {
        final pppoeUsername = await routerService.getPppoeUsername();
        if (pppoeUsername != null) {
          await ref.read(authProvider.notifier).tryBackendLogin(
            provinceName: widget.province.name,
            pppoeUsername: pppoeUsername,
          );
        }
      } catch (_) {}

      ref.read(authProvider.notifier).markAuthenticated();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      setState(() => _errorMessage = _friendlyErrorMessage(e));
    } finally {
      await routerService?.close();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 🧪 TEST MODE
  Future<void> _handleTestLogin() async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('ورود آزمایشی (بدون روتر)'),
        content: TextField(
          controller: c,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'یوزرنیم PPPoE واقعی',
            hintText: 'مثلاً MatinHome',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('انصراف')),
          TextButton(
              onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('ورود')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;

    setState(() => _isSubmitting = true);
    await ref.read(authProvider.notifier).tryBackendLogin(
      provinceName: widget.province.name,
      pppoeUsername: result,
    );
    await SecureStorageService.saveRouterCredentials('test', 'test');
    ref.read(authProvider.notifier).markAuthenticated();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  Future<void> _changeProvince() async {
    await SecureStorageService.deleteProvince();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProvinceSelectScreen()),
    );
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('باز کردن لینک ممکن نشد')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final support = kSupportByProvince[widget.province.name] ?? kDefaultSupport;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(26),
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
                ),
                const SizedBox(height: 22),
                const Text('ورود به حساب',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _changeProvince,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(widget.province.displayName,
                              style: const TextStyle(
                                  color: AppColors.primary, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          const Text('تغییر',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppDecor.card(radius: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _idController,
                        textDirection: TextDirection.ltr,
                        autocorrect: false,
                        enableSuggestions: false,
                        onSubmitted: (_) => _isSubmitting ? null : _handleLogin(),
                        decoration: const InputDecoration(
                          labelText: 'آیدی کاربری',
                          hintText: 'لطفاً آیدی یا یوزر کاربری خود را وارد کنید',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
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
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: AppColors.danger, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleLogin,
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        )
                            : const Text('ورود'),
                      ),
                      if (kEnableTestLoginBypass) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isSubmitting ? null : _handleTestLogin,
                          child: const Text('🧪 ورود آزمایشی (بدون اتصال به روتر)',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                _supportSection(support),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _supportSection(SupportContact support) {
    return Column(
      children: [
        const Text(
          'برای دریافت آیدی کاربری به واتساپ یا تلگرام شرکت ما پیام بدهید',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.7),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _supportButton(
                label: 'تلگرام',
                icon: Icons.send_rounded,
                color: const Color(0xFF229ED9),
                onTap: () => _open(support.telegramUrl),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _supportButton(
                label: 'واتساپ',
                icon: Icons.chat_rounded,
                color: const Color(0xFF25D366),
                onTap: () => _open('https://wa.me/${support.whatsappNumber}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(support.displayPhone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _supportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}