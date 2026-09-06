/// Representa um protocolo de jejum, ex: 16:8 -> 16h jejum, 8h alimentação.
/// fastingHours é `double` para permitir protocolos de teste com poucos
/// minutos (ex: 0.1h = 6min) sem quebrar os protocolos padrão em horas
/// inteiras.
class FastingProtocolModel {
  final String id;
  final String name;
  final double fastingHours;
  final double eatingHours;
  final bool isCustom;

  const FastingProtocolModel({
    required this.id,
    required this.name,
    required this.fastingHours,
    required this.eatingHours,
    this.isCustom = false,
  });

  Duration get fastingDuration =>
      Duration(seconds: (fastingHours * 3600).round());

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'fastingHours': fastingHours,
        'eatingHours': eatingHours,
        'isCustom': isCustom,
      };

  factory FastingProtocolModel.fromMap(Map<dynamic, dynamic> map) =>
      FastingProtocolModel(
        id: map['id'] as String,
        name: map['name'] as String,
        fastingHours: (map['fastingHours'] as num).toDouble(),
        eatingHours: (map['eatingHours'] as num).toDouble(),
        isCustom: map['isCustom'] as bool? ?? false,
      );

  static const List<FastingProtocolModel> predefined = [
    FastingProtocolModel(
        id: 'p_12_12', name: '12:12', fastingHours: 12, eatingHours: 12),
    FastingProtocolModel(
        id: 'p_16_8', name: '16:8', fastingHours: 16, eatingHours: 8),
    FastingProtocolModel(
        id: 'p_18_6', name: '18:6', fastingHours: 18, eatingHours: 6),
  ];
}
