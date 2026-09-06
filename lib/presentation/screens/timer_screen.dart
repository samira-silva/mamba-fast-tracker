import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fasting_provider.dart';
import '../providers/meal_provider.dart';
import '../../data/models/fasting_protocol_model.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => _CustomProtocolDialog(fasting: fasting),
    );
  }

  Future<void> _confirmDelete(BuildContext context, FastingProtocolModel p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir protocolo?'),
        content: Text('Isso remove o protocolo "${p.name}" da sua lista. Jejuns já '
            'registrados com ele continuam no histórico.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await fasting.deleteCustomProtocol(p.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final predefined = fasting.protocols.where((p) => !p.isCustom).toList();
    final custom = fasting.protocols.where((p) => p.isCustom).toList();

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
              children: predefined
                  .map((p) => ActionChip(
                        label: Text(p.name),
                        onPressed: () => fasting.startFasting(p),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showCustomDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Criar protocolo customizado'),
            ),
            if (custom.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Seus protocolos', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              ...custom.map((p) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Material(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => fasting.startFasting(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_empty, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(p.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: AppColors.danger,
                                onPressed: () => _confirmDelete(context, p),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
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

/// Diálogo de protocolo customizado. Em vez de pedir um número decimal de
/// horas (confuso: "0.1" pra 6 minutos), usamos campos separados de horas
/// e minutos, além de atalhos rápidos pra durações comuns e pra testes.
class _CustomProtocolDialog extends StatefulWidget {
  final FastingProvider fasting;
  const _CustomProtocolDialog({required this.fasting});

  @override
  State<_CustomProtocolDialog> createState() => _CustomProtocolDialogState();
}

class _CustomProtocolDialogState extends State<_CustomProtocolDialog> {
  final nameCtrl = TextEditingController();
  double _hours = 14;
  bool _nameEditedByUser = false;

  String get _autoName => '${_hours.round()}:${24 - _hours.round()}';

  @override
  void initState() {
    super.initState();
    nameCtrl.text = _autoName;
  }

  void _onSliderChanged(double value) {
    setState(() => _hours = value);
    if (!_nameEditedByUser) {
      nameCtrl.text = _autoName;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo protocolo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quantas horas de jejum?', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${_hours.round()}h',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
          ),
          Slider(
            value: _hours,
            min: 1,
            max: 23,
            divisions: 22,
            label: '${_hours.round()}h',
            onChanged: _onSliderChanged,
          ),
          Text(
            'Isso deixa ${24 - _hours.round()}h para se alimentar por dia.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome do protocolo'),
            onChanged: (_) => _nameEditedByUser = true,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            await widget.fasting.createCustomProtocol(nameCtrl.text, _hours);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
