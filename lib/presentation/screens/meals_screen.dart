import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../../data/models/meal_model.dart';
import '../../core/utils/date_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/food_database.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  void _showMealDialog(BuildContext context, {MealModel? existing}) {
    final mealProvider = context.read<MealProvider>();
    showDialog(
      context: context,
      builder: (ctx) => _MealDialog(existing: existing, mealProvider: mealProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealProvider>();
    final today = meals.todayMeals;

    return Scaffold(
      body: today.isEmpty
          ? const Center(child: Text('Nenhuma refeição hoje ainda.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: today.length,
              itemBuilder: (context, i) {
                final m = today[i];
                return Card(
                  child: ListTile(
                    title: Text(m.name),
                    subtitle: Text('${m.calories} kcal • ${formatTime(m.time)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showMealDialog(context, existing: m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: AppColors.danger),
                          onPressed: () => meals.deleteMeal(m.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMealDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _QtyMode { grams, units }

/// Diálogo de criar/editar refeição. Enquanto a pessoa digita o nome do
/// alimento, sugerimos alimentos conhecidos (chips). Pra alimentos
/// contáveis (banana, ovo, fatia de pão...), a pessoa pode escolher
/// informar a quantidade em UNIDADES em vez de gramas — o app converte
/// pra gramas usando um peso médio de referência e sugere as calorias.
/// Tudo local, sem API externa (mais um ponto de falha evitado).
class _MealDialog extends StatefulWidget {
  final MealModel? existing;
  final MealProvider mealProvider;

  const _MealDialog({required this.existing, required this.mealProvider});

  @override
  State<_MealDialog> createState() => _MealDialogState();
}

class _MealDialogState extends State<_MealDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController calCtrl;
  final qtyCtrl = TextEditingController();
  List<String> _suggestions = const [];
  int? _suggestedCalories;
  String? _matchedFood;
  double? _matchedGrams;
  _QtyMode _mode = _QtyMode.grams;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    calCtrl = TextEditingController(text: widget.existing?.calories.toString() ?? '');
    nameCtrl.addListener(_onNameChanged);
    qtyCtrl.addListener(_recompute);
  }

  bool get _hasUnitOption => _matchedFood != null && kFoodUnitWeightGrams.containsKey(_matchedFood);

  void _onNameChanged() {
    final query = nameCtrl.text.trim();
    final exactMatch = kFoodCaloriesPer100g.keys
        .where((f) => f.toLowerCase() == query.toLowerCase());
    final matched = exactMatch.isNotEmpty ? exactMatch.first : null;

    setState(() {
      _suggestions = matched == null ? searchFoods(query) : const [];
      _matchedFood = matched;
      // Se o alimento novo não tem opção de unidade, volta pra gramas.
      if (matched == null || !kFoodUnitWeightGrams.containsKey(matched)) {
        _mode = _QtyMode.grams;
      }
    });
    _recompute();
  }

  void _recompute() {
    final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
    double? grams;
    if (qty != null && qty > 0 && _matchedFood != null) {
      if (_mode == _QtyMode.units && kFoodUnitWeightGrams.containsKey(_matchedFood)) {
        grams = qty * kFoodUnitWeightGrams[_matchedFood]!;
      } else if (_mode == _QtyMode.grams) {
        grams = qty;
      }
    }
    setState(() {
      _matchedGrams = grams;
      _suggestedCalories = (grams != null && _matchedFood != null)
          ? suggestedCalories(_matchedFood!, grams)
          : null;
    });
  }

  void _pickSuggestion(String food) {
    nameCtrl.text = food;
    setState(() => _suggestions = const []);
    _onNameChanged();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    calCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nova refeição' : 'Editar refeição'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do alimento',
                helperText: 'Digite e toque numa sugestão, se aparecer',
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _suggestions
                    .map((f) => ActionChip(
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _pickSuggestion(f),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (_hasUnitOption) ...[
              Row(
                children: [
                  Text('Medir por:', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Gramas'),
                    selected: _mode == _QtyMode.grams,
                    onSelected: (_) {
                      setState(() => _mode = _QtyMode.grams);
                      _recompute();
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Unidades'),
                    selected: _mode == _QtyMode.units,
                    onSelected: (_) {
                      setState(() => _mode = _QtyMode.units);
                      _recompute();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _mode == _QtyMode.units
                    ? 'Quantidade (unidades) — opcional'
                    : 'Quantidade (g) — opcional',
                helperText: _mode == _QtyMode.units && _matchedFood != null
                    ? '1 unidade ≈ ${kFoodUnitWeightGrams[_matchedFood]}g'
                    : 'Preenche a sugestão de calorias automaticamente',
              ),
            ),
            if (_suggestedCalories != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.accentDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mode == _QtyMode.units
                            ? 'Sugestão: $_suggestedCalories kcal (${_matchedGrams?.round()}g de $_matchedFood)'
                            : 'Sugestão: $_suggestedCalories kcal (baseado em $_matchedFood)',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => calCtrl.text = _suggestedCalories.toString()),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calorias'),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Horário: registrado automaticamente',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            final calories = int.tryParse(calCtrl.text) ?? 0;
            if (nameCtrl.text.isEmpty || calories <= 0) return;
            if (widget.existing == null) {
              await widget.mealProvider.addMeal(nameCtrl.text, calories);
            } else {
              await widget.mealProvider.updateMeal(
                  widget.existing!.copyWith(name: nameCtrl.text, calories: calories));
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
