import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/fasting_provider.dart';
import '../providers/meal_provider.dart';
import '../../data/repositories/fasting_repository.dart';
import '../../data/repositories/meal_repository.dart';
import 'timer_screen.dart';
import 'meals_screen.dart';
import 'history_screen.dart';
import 'chart_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userId = context.read<AuthProvider>().user!.id;
    final fastingProvider = FastingProvider(FastingRepository(userId));
    final mealProvider = MealProvider(MealRepository(userId));
    await fastingProvider.init();
    await mealProvider.init();
    if (!mounted) return;
    setState(() {
      _fastingProvider = fastingProvider;
      _mealProvider = mealProvider;
      _ready = true;
    });
  }

  FastingProvider? _fastingProvider;
  MealProvider? _mealProvider;

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _fastingProvider!),
        ChangeNotifierProvider.value(value: _mealProvider!),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mamba Fast Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: const [
            TimerScreen(),
            MealsScreen(),
            HistoryScreen(),
            ChartScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.timer), label: 'Jejum'),
            NavigationDestination(icon: Icon(Icons.restaurant), label: 'Refeições'),
            NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Gráfico'),
          ],
        ),
      ),
    );
  }
}
