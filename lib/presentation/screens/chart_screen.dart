import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/meal_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealProvider>();
    final byDay = meals.caloriesByDay;

    final sortedKeys = byDay.keys.toList()..sort();
    final last7 = sortedKeys.length > 7
        ? sortedKeys.sublist(sortedKeys.length - 7)
        : sortedKeys;

    if (last7.isEmpty) {
      return _EmptyState(
        icon: Icons.show_chart_rounded,
        message: 'Sem dados suficientes para o gráfico ainda.',
        hint: 'Registre refeições em mais de um dia pra ver sua evolução aqui.',
      );
    }

    // Com um único dia de dado, um gráfico de linha fica sem sentido (um
    // ponto sozinho não mostra tendência nenhuma). Mostramos um resumo
    // simples em vez de forçar um gráfico vazio.
    if (last7.length == 1) {
      final onlyDay = last7.first;
      final value = byDay[onlyDay] ?? 0;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calorias', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$value',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('kcal', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(_formatDayKey(onlyDay), style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 28),
                    const Text(
                      'Ainda há só um dia registrado.\nO gráfico de evolução aparece a partir\nde 2 dias com refeições.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < last7.length; i++) {
      spots.add(FlSpot(i.toDouble(), (byDay[last7[i]] ?? 0).toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calorias — últimos ${last7.length} dias',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= last7.length) return const SizedBox();
                        final parts = last7[idx].split('-');
                        return Text('${parts[2]}/${parts[1]}',
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayKey(String key) {
    final parts = key.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return formatDayLabel(date);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const _EmptyState({required this.icon, required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(hint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
