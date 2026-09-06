enum FastingStatus { idle, running, paused, completed }

/// Sessão de jejum: guarda apenas timestamps absolutos (não um contador em
/// memória). Isso é o que garante que o timer sobrevive a fechar o app,
/// matar o processo ou reiniciar o celular: o tempo decorrido é sempre
/// recalculado a partir de `startedAt` / `pausedAt` / `now`, nunca guardado
/// como "segundos restantes" em uma variável volátil.
class FastingSessionModel {
  final String id;
  final String protocolId;
  final String protocolName;
  final double targetFastingHours;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final Duration accumulatedPause; // tempo total já pausado, descontado do jejum
  final DateTime? endedAt;
  final FastingStatus status;

  FastingSessionModel({
    required this.id,
    required this.protocolId,
    required this.protocolName,
    required this.targetFastingHours,
    required this.startedAt,
    this.pausedAt,
    this.accumulatedPause = Duration.zero,
    this.endedAt,
    this.status = FastingStatus.running,
  });

  Duration get targetDuration =>
      Duration(seconds: (targetFastingHours * 3600).round());

  /// Tempo decorrido de jejum efetivo (desconta pausas), calculado sob demanda.
  Duration elapsed({DateTime? now}) {
    final reference = endedAt ?? (status == FastingStatus.paused ? pausedAt! : (now ?? DateTime.now()));
    final raw = reference.difference(startedAt);
    final result = raw - accumulatedPause;
    return result.isNegative ? Duration.zero : result;
  }

  Duration remaining({DateTime? now}) {
    final rem = targetDuration - elapsed(now: now);
    return rem.isNegative ? Duration.zero : rem;
  }

  bool get isGoalReached => elapsed() >= targetDuration;

  FastingSessionModel copyWith({
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? accumulatedPause,
    DateTime? endedAt,
    FastingStatus? status,
  }) {
    return FastingSessionModel(
      id: id,
      protocolId: protocolId,
      protocolName: protocolName,
      targetFastingHours: targetFastingHours,
      startedAt: startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      accumulatedPause: accumulatedPause ?? this.accumulatedPause,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'protocolId': protocolId,
        'protocolName': protocolName,
        'targetFastingHours': targetFastingHours,
        'startedAt': startedAt.toIso8601String(),
        'pausedAt': pausedAt?.toIso8601String(),
        'accumulatedPauseMs': accumulatedPause.inMilliseconds,
        'endedAt': endedAt?.toIso8601String(),
        'status': status.name,
      };

  factory FastingSessionModel.fromMap(Map<dynamic, dynamic> map) =>
      FastingSessionModel(
        id: map['id'] as String,
        protocolId: map['protocolId'] as String,
        protocolName: map['protocolName'] as String,
        targetFastingHours: (map['targetFastingHours'] as num).toDouble(),
        startedAt: DateTime.parse(map['startedAt'] as String),
        pausedAt: map['pausedAt'] != null ? DateTime.parse(map['pausedAt'] as String) : null,
        accumulatedPause: Duration(milliseconds: map['accumulatedPauseMs'] as int? ?? 0),
        endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt'] as String) : null,
        status: FastingStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => FastingStatus.idle,
        ),
      );
}
