import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Encapsula agendamento/disparo de notificações locais para início e fim
/// do jejum. Usamos `zonedSchedule` para o término (agendado no futuro) e
/// `show` imediato para o início.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    // Android 13+: pede permissão de notificação em runtime.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> notifyFastingStarted(String protocolName) async {
    await _plugin.show(
      1001,
      'Jejum iniciado 🕒',
      'Protocolo $protocolName. Boa sorte!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fasting_channel',
          'Jejum',
          channelDescription: 'Notificações de início e fim de jejum',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Agenda a notificação de término no horário exato em que a meta é
  /// atingida. Cancelamos e reagendamos sempre que o timer é pausado/retomado
  /// para manter o horário preciso.
  Future<void> scheduleFastingEnd(DateTime endTime, String protocolName) async {
    await cancelFastingEndNotification();
    final scheduled = tz.TZDateTime.from(endTime, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      1002,
      'Jejum concluído! 🎉',
      'Você bateu a meta do protocolo $protocolName.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fasting_channel',
          'Jejum',
          channelDescription: 'Notificações de início e fim de jejum',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelFastingEndNotification() async {
    await _plugin.cancel(1002);
  }
}
