import 'package:hive_flutter/hive_flutter.dart';

/// Centraliza nomes e abertura das boxes do Hive.
/// Guardamos tudo como `Map<String, dynamic>` (sem TypeAdapter gerado por
/// codegen) para manter o projeto simples de compilar sem build_runner.
class HiveBoxes {
  static const String users = 'users_box';
  static const String sessionPrefix = 'fasting_sessions_'; // + userId
  static const String mealsPrefix = 'meals_'; // + userId
  static const String protocolsPrefix = 'protocols_'; // + userId
  static const String settings = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(users);
    await Hive.openBox(settings);
  }

  static Future<Box> openUserBox(String prefix, String userId) async {
    final boxName = '$prefix$userId';
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return Hive.openBox(boxName);
  }
}
