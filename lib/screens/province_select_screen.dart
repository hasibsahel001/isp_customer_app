import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province.dart';
import '../providers/auth_provider.dart';
import '../services/secure_storage_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProvinceSelectScreen extends ConsumerStatefulWidget {
  const ProvinceSelectScreen({super.key});

  @override
  ConsumerState<ProvinceSelectScreen> createState() => _ProvinceSelectScreenState();
}

class _ProvinceSelectScreenState extends ConsumerState<ProvinceSelectScreen> {
  // ولایت‌هایی که هنوز فعال نیستند (فقط نمایش)
  static const _comingSoon = ['مزار شریف'];

  List<Province> _active = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(apiServiceProvider).getProvinces();
      setState(() {
        _active = list;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'خطا در دریافت لیست ولایت‌ها. اتصال اینترنت را بررسی کنید.';
      });
    }
  }

  Future<void> _select(Province p) async {
    await SecureStorageService.saveProvince(p.name);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(province: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
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
            const SizedBox(height: 26),
            const Text('خوش آمدید',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('لطفاً ولایت خود را انتخاب کنید',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 30),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null) ...[
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('تلاش دوباره')),
            ] else ...[
              ..._active.map((p) => _provinceTile(
                title: p.displayName,
                enabled: true,
                onTap: () => _select(p),
              )),
              ..._comingSoon.map((n) => _provinceTile(
                title: n,
                enabled: false,
                subtitle: 'به‌زودی اضافه می‌گردد',
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _provinceTile({
    required String title,
    required bool enabled,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          decoration: AppDecor.card(),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (enabled ? AppColors.primary : AppColors.textSecondary)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.location_city_rounded,
                        color: enabled ? AppColors.primary : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.warning)),
                        ],
                      ],
                    ),
                  ),
                  if (enabled)
                    const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary)
                  else
                    const Icon(Icons.lock_clock_rounded,
                        color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}