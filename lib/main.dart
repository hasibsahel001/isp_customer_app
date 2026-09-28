import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/province.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/province_select_screen.dart';
import 'services/secure_storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ مشتریان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const MainNavigationScreen();
      case AuthStatus.unauthenticated:
        return const _LoggedOutRouter();
    }
  }
}

// تصمیم بین صفحهٔ انتخاب ولایت و صفحهٔ لاگین
class _LoggedOutRouter extends ConsumerWidget {
  const _LoggedOutRouter();

  Future<Province?> _savedProvince(WidgetRef ref) async {
    final name = await SecureStorageService.getProvince();
    if (name == null) return null;
    try {
      final list = await ref.read(apiServiceProvider).getProvinces();
      for (final p in list) {
        if (p.name == name) return p;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Province?>(
      future: _savedProvince(ref),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final p = snap.data;
        if (p == null) return const ProvinceSelectScreen();
        return LoginScreen(province: p);
      },
    );
  }
}