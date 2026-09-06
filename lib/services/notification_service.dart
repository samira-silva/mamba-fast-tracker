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
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    // Android 12+ (API 31+): a notificação de término do jejum é agendada
    // com precisão exata (zonedSchedule + exactAllowWhileIdle), o que exige
    // a permissão especial "Alarmes e lembretes". Sem pedir isso
    // explicitamente aqui, o agendamento falha silenciosamente em telefones
    // mais novos — foi exatamente o bug que encontramos testando no
    // dispositivo real. Isso mostra o popup do sistema (ou leva direto pra
    // tela de configuração do app, dependendo da versão do Android).
    await androidPlugin?.requestExactAlarmsPermission();
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

    // Se o usuário não concedeu "Alarmes e lembretes", um agendamento
    // "exact" falha silenciosamente no Android 12+. Nesse caso, caímos
    // para "inexact" (o SO pode atrasar em minutos, mas ainda dispara) em
    // vez de simplesmente não notificar o usuário.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    final mode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

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
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelFastingEndNotification() async {
    await _plugin.cancel(1002);
  }
}
