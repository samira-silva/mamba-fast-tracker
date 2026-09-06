import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/local/hive_boxes.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'services/notification_service.dart';
import 'core/constants/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await NotificationService().init();
  runApp(const MambaFastTrackerApp());
}

class MambaFastTrackerApp extends StatelessWidget {
  const MambaFastTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..restoreSession(),
      child: MaterialApp(
        title: 'Mamba Fast Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: AppColors.primary,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Decide entre tela de login e home com base no estado de autenticação
/// restaurado (auto-login se já havia sessão persistida).
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.state) {
      case AuthState.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthState.authenticated:
        return const HomeScreen();
      case AuthState.unauthenticated:
        return const LoginScreen();
    }
  }
}
