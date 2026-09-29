import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/province_select_screen.dart';
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

    switch (authState.stage) {
      case AuthStage.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStage.needProvince:
        return const ProvinceSelectScreen();
      case AuthStage.needLogin:
        return LoginScreen(province: authState.province!);
      case AuthStage.authenticated:
        return const MainNavigationScreen();
    }
  }
}