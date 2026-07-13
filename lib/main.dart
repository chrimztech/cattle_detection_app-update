import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_page.dart';
import 'login_page.dart';
import 'session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UnzaCattleMobileApp());
}

class UnzaCattleMobileApp extends StatelessWidget {
  const UnzaCattleMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionController()..bootstrap(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UNZA Cattle Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009739)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF6F7F3),
        ),
        home: const AppBootstrapper(),
      ),
    );
  }
}

class AppBootstrapper extends StatelessWidget {
  const AppBootstrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.bootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return session.isAuthenticated ? const DashboardPage() : const LoginPage();
  }
}
