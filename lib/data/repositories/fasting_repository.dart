import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../models/fasting_protocol_model.dart';
import '../models/fasting_session_model.dart';

class FastingRepository {
  final String userId;
  final _uuid = const Uuid();
  Box? _sessionsBox;
  Box? _protocolsBox;

  FastingRepository(this.userId);

  Future<void> init() async {
    _sessionsBox = await HiveBoxes.openUserBox(HiveBoxes.sessionPrefix, userId);
    _protocolsBox = await HiveBoxes.openUserBox(HiveBoxes.protocolsPrefix, userId);
  }

  // ---------------- Protocolos ----------------

  List<FastingProtocolModel> getCustomProtocols() {
    return _protocolsBox!.values
        .map((v) => FastingProtocolModel.fromMap(v as Map))
        .toList();
  }

  List<FastingProtocolModel> getAllProtocols() => [
        ...FastingProtocolModel.predefined,
        ...getCustomProtocols(),
      ];

  Future<FastingProtocolModel> createCustomProtocol(
      String name, double fastingHours) async {
    final protocol = FastingProtocolModel(
      id: _uuid.v4(),
      name: name,
      fastingHours: fastingHours,
      eatingHours: 24 - fastingHours,
      isCustom: true,
    );
    await _protocolsBox!.put(protocol.id, protocol.toMap());
    return protocol;
  }

  Future<void> deleteCustomProtocol(String id) async {
    await _protocolsBox!.delete(id);
  }

  // ---------------- Sessões ----------------

  /// Retorna a sessão ativa (running ou paused), se houver.
  FastingSessionModel? getActiveSession() {
    final all = _sessionsBox!.values
        .map((v) => FastingSessionModel.fromMap(v as Map))
        .toList();
    for (final s in all) {
      if (s.status == FastingStatus.running || s.status == FastingStatus.paused) {
        return s;
      }
    }
    return null;
  }

  List<FastingSessionModel> getAllSessions() {
    final list = _sessionsBox!.values
        .map((v) => FastingSessionModel.fromMap(v as Map))
        .toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  Future<FastingSessionModel> startFasting(FastingProtocolModel protocol) async {
    if (getActiveSession() != null) {
      throw Exception('Já existe um jejum em andamento.');
    }
    final session = FastingSessionModel(
      id: _uuid.v4(),
      protocolId: protocol.id,
      protocolName: protocol.name,
      targetFastingHours: protocol.fastingHours,
      startedAt: DateTime.now(),
      status: FastingStatus.running,
    );
    await _sessionsBox!.put(session.id, session.toMap());
    return session;
  }

  Future<FastingSessionModel> pauseFasting(FastingSessionModel session) async {
    final updated = session.copyWith(
      status: FastingStatus.paused,
      pausedAt: DateTime.now(),
    );
    await _sessionsBox!.put(updated.id, updated.toMap());
    return updated;
  }

  Future<FastingSessionModel> resumeFasting(FastingSessionModel session) async {
    final pauseDuration = session.pausedAt != null
        ? DateTime.now().difference(session.pausedAt!)
        : Duration.zero;
    final updated = session.copyWith(
      status: FastingStatus.running,
      clearPausedAt: true,
      accumulatedPause: session.accumulatedPause + pauseDuration,
    );
    await _sessionsBox!.put(updated.id, updated.toMap());
    return updated;
  }

  Future<FastingSessionModel> endFasting(FastingSessionModel session) async {
    final updated = session.copyWith(
      status: FastingStatus.completed,
      endedAt: DateTime.now(),
    );
    await _sessionsBox!.put(updated.id, updated.toMap());
    return updated;
  }
}
