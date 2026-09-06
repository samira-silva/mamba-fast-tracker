import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fasting_provider.dart';
import '../providers/meal_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fasting = context.watch<FastingProvider>();
    final meals = context.watch<MealProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!fasting.hasActive) _ProtocolPicker(fasting: fasting),
          if (fasting.hasActive) _ActiveTimer(fasting: fasting),
          const SizedBox(height: 24),
          _DailySummaryCard(meals: meals, fasting: fasting),
        ],
      ),
    );
  }
}

class _ProtocolPicker extends StatelessWidget {
  final FastingProvider fasting;
  const _ProtocolPicker({required this.fasting});

  void _showCustomDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Protocolo customizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome (ex: 20:4)'),
            ),
            TextField(
              controller: hoursCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Horas de jejum',
                helperText: 'Aceita decimal. Ex: 0.1 = 6 min (útil para teste)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final hours = double.tryParse(hoursCtrl.text.replaceAll(',', '.')) ?? 0;
              if (nameCtrl.text.isEmpty || hours <= 0 || hours >= 24) return;
              await fasting.createCustomProtocol(nameCtrl.text, hours);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Escolha um protocolo',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fasting.protocols.map((p) {
                return ActionChip(
                  label: Text('${p.name}${p.isCustom ? ' •' : ''}'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  onPressed: () => fasting.startFasting(p),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showCustomDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Criar protocolo customizado'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTimer extends StatelessWidget {
  final FastingProvider fasting;
  const _ActiveTimer({required this.fasting});

  @override
  Widget build(BuildContext context) {
    final progress = fasting.elapsed.inSeconds /
        (fasting.activeSession!.targetDuration.inSeconds == 0
            ? 1
            : fasting.activeSession!.targetDuration.inSeconds);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Protocolo ${fasting.activeSession!.protocolName}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    strokeWidth: 10,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      fasting.activeSession!.isGoalReached
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatDuration(fasting.elapsed),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('decorrido'),
                      const SizedBox(height: 8),
                      Text(
                        fasting.activeSession!.isGoalReached
                            ? 'Meta atingida! 🎉'
                            : 'faltam ${formatDuration(fasting.remaining)}',
                        style: TextStyle(
                          color: fasting.activeSession!.isGoalReached
                              ? AppColors.success
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (fasting.isRunning)
                  OutlinedButton.icon(
                    onPressed: fasting.pauseFasting,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pausar'),
                  ),
                if (fasting.isPaused)
                  OutlinedButton.icon(
                    onPressed: fasting.resumeFasting,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Retomar'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => fasting.endFasting(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white),
                  icon: const Icon(Icons.stop),
                  label: const Text('Encerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final MealProvider meals;
  final FastingProvider fasting;
  const _DailySummaryCard({required this.meals, required this.fasting});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo de hoje', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row('Calorias', '${meals.todayCalories} kcal'),
            _row('Status', meals.isWithinGoal ? 'Dentro da meta ✅' : 'Fora da meta ⚠️'),
            _row('Jejum decorrido hoje', formatDuration(fasting.elapsed)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
        ),
      );
}
