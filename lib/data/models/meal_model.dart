class MealModel {
  final String id;
  final String name;
  final int calories;
  final DateTime time;

  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.time,
  });

  /// Chave do dia (yyyy-MM-dd) usada para agrupar refeições/sessões por dia.
  String get dayKey =>
      '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

  MealModel copyWith({String? name, int? calories, DateTime? time}) =>
      MealModel(
        id: id,
        name: name ?? this.name,
        calories: calories ?? this.calories,
        time: time ?? this.time,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'calories': calories,
        'time': time.toIso8601String(),
      };

  factory MealModel.fromMap(Map<dynamic, dynamic> map) => MealModel(
        id: map['id'] as String,
        name: map['name'] as String,
        calories: map['calories'] as int,
        time: DateTime.parse(map['time'] as String),
      );
}
