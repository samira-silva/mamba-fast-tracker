import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/fasting_protocol_model.dart';
import '../../data/models/fasting_session_model.dart';
import '../../data/repositories/fasting_repository.dart';
import '../../services/notification_service.dart';

/// Provider responsável pelo timer de jejum. É observador do ciclo de vida
/// do app (WidgetsBindingObserver): ao voltar do background
/// (AppLifecycleState.resumed) ele reconsulta a hora atual e recalcula o
/// tempo decorrido/restante a partir do timestamp persistido — nunca deixa
/// um Timer.periodic "correndo" sozinho contando de forma imprecisa.
class FastingProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FastingRepository repository;
  final NotificationService _notifications = NotificationService();

  FastingSessionModel? activeSession;
  Timer? _ticker;
  Duration elapsed = Duration.zero;
  Duration remaining = Duration.zero;

  FastingProvider(this.repository) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() async {
    await repository.init();
    activeSession = repository.getActiveSession();
    _recompute();
    _startTicker();
  }

  List<FastingProtocolModel> get protocols => repository.getAllProtocols();
  List<FastingSessionModel> get history => repository.getAllSessions();

  bool get isRunning => activeSession?.status == FastingStatus.running;
  bool get isPaused => activeSession?.status == FastingStatus.paused;
  bool get hasActive => activeSession != null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalcula com base no relógio real, cobrindo o tempo em que o app
      // ficou fechado/suspenso.
      _recompute();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  void _recompute() {
    if (activeSession != null && activeSession!.status == FastingStatus.running) {
      elapsed = activeSession!.elapsed();
      remaining = activeSession!.remaining();
    } else if (activeSession != null && activeSession!.status == FastingStatus.paused) {
      elapsed = activeSession!.elapsed();
      remaining = activeSession!.remaining();
    } else {
      elapsed = Duration.zero;
      remaining = Duration.zero;
    }
    notifyListeners();
  }

  Future<void> startFasting(FastingProtocolModel protocol) async {
    activeSession = await repository.startFasting(protocol);
    await _notifications.notifyFastingStarted(protocol.name);
    final endTime = activeSession!.startedAt.add(activeSession!.targetDuration);
    await _notifications.scheduleFastingEnd(endTime, protocol.name);
    _recompute();
  }

  Future<void> pauseFasting() async {
    if (activeSession == null) return;
    activeSession = await repository.pauseFasting(activeSession!);
    await _notifications.cancelFastingEndNotification();
    _recompute();
  }

  Future<void> resumeFasting() async {
    if (activeSession == null) return;
    activeSession = await repository.resumeFasting(activeSession!);
    final endTime = activeSession!.startedAt
        .add(activeSession!.targetDuration)
        .add(activeSession!.accumulatedPause);
    await _notifications.scheduleFastingEnd(endTime, activeSession!.protocolName);
    _recompute();
  }

  Future<void> endFasting() async {
    if (activeSession == null) return;
    await repository.endFasting(activeSession!);
    await _notifications.cancelFastingEndNotification();
    activeSession = null;
    _recompute();
  }

  Future<FastingProtocolModel> createCustomProtocol(String name, double hours) {
    return repository.createCustomProtocol(name, hours);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}
