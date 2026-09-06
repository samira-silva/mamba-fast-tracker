import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../models/meal_model.dart';

class MealRepository {
  final String userId;
  final _uuid = const Uuid();
  Box? _box;

  MealRepository(this.userId);

  Future<void> init() async {
    _box = await HiveBoxes.openUserBox(HiveBoxes.mealsPrefix, userId);
  }

  List<MealModel> getAll() {
    final list = _box!.values.map((v) => MealModel.fromMap(v as Map)).toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  List<MealModel> getForDay(String dayKey) =>
      getAll().where((m) => m.dayKey == dayKey).toList();

  Future<MealModel> addMeal(String name, int calories, {DateTime? time}) async {
    final meal = MealModel(
      id: _uuid.v4(),
      name: name,
      calories: calories,
      time: time ?? DateTime.now(),
    );
    await _box!.put(meal.id, meal.toMap());
    return meal;
  }

  Future<MealModel> updateMeal(MealModel meal) async {
    await _box!.put(meal.id, meal.toMap());
    return meal;
  }

  Future<void> deleteMeal(String id) async {
    await _box!.delete(id);
  }

  /// Agrupa por dia -> total de calorias (usado no gráfico/histórico).
  Map<String, int> caloriesByDay() {
    final map = <String, int>{};
    for (final m in getAll()) {
      map[m.dayKey] = (map[m.dayKey] ?? 0) + m.calories;
    }
    return map;
  }
}
