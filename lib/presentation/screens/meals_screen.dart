import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../../data/models/meal_model.dart';
import '../../core/utils/date_utils.dart';
import '../../core/constants/app_colors.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  void _showMealDialog(BuildContext context, {MealModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final calCtrl =
        TextEditingController(text: existing?.calories.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nova refeição' : 'Editar refeição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calorias'),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Horário: registrado automaticamente',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final calories = int.tryParse(calCtrl.text) ?? 0;
              if (nameCtrl.text.isEmpty || calories <= 0) return;
              final provider = ctx.read<MealProvider>();
              if (existing == null) {
                await provider.addMeal(nameCtrl.text, calories);
              } else {
                await provider.updateMeal(
                    existing.copyWith(name: nameCtrl.text, calories: calories));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
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
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
