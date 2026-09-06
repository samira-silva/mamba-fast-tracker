import 'package:flutter/foundation.dart';
import '../../data/models/meal_model.dart';
import '../../data/repositories/meal_repository.dart';

class MealProvider extends ChangeNotifier {
  final MealRepository repository;
  static const int dailyCalorieGoal = 2000;

  MealProvider(this.repository);

  Future<void> init() async {
    await repository.init();
    notifyListeners();
  }

  List<MealModel> get meals => repository.getAll();

  String get todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<MealModel> get todayMeals => repository.getForDay(todayKey);

  int get todayCalories =>
      todayMeals.fold(0, (sum, m) => sum + m.calories);

  bool get isWithinGoal => todayCalories <= dailyCalorieGoal;

  Map<String, int> get caloriesByDay => repository.caloriesByDay();

  Future<void> addMeal(String name, int calories) async {
    await repository.addMeal(name, calories);
    notifyListeners();
  }

  Future<void> updateMeal(MealModel meal) async {
    await repository.updateMeal(meal);
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    await repository.deleteMeal(id);
    notifyListeners();
  }
}
