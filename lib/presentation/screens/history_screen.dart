import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fasting_provider.dart';
import '../providers/meal_provider.dart';
import '../../core/utils/date_utils.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fasting = context.watch<FastingProvider>();
    final meals = context.watch<MealProvider>();
    final sessions = fasting.history;

    if (sessions.isEmpty) {
      return const Center(child: Text('Nenhum jejum concluído ainda.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[i];
        final dayKey =
            '${s.startedAt.year.toString().padLeft(4, '0')}-${s.startedAt.month.toString().padLeft(2, '0')}-${s.startedAt.day.toString().padLeft(2, '0')}';
        final dayCalories = meals.caloriesByDay[dayKey] ?? 0;

        return Card(
          child: ListTile(
            title: Text('${formatDayLabel(s.startedAt)} • Protocolo ${s.protocolName}'),
            subtitle: Text(
              'Jejum: ${formatDuration(s.elapsed())}  •  Calorias do dia: $dayCalories kcal',
            ),
            trailing: Icon(
              s.status.name == 'completed' ? Icons.check_circle : Icons.hourglass_bottom,
              color: s.status.name == 'completed' ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }
}
