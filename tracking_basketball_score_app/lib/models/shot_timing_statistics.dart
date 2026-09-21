import 'training_session.dart';

class ShotTimingStatistics {
  const ShotTimingStatistics({
    required this.makeTimesMs,
    required this.missTimesMs,
  });

  final List<int> makeTimesMs;
  final List<int> missTimesMs;

  int? get averageMakeMs => _average(makeTimesMs);
  int? get averageMissMs => _average(missTimesMs);
  int get trackedShots => makeTimesMs.length + missTimesMs.length;

  int? _average(List<int> values) {
    if (values.isEmpty) {
      return null;
    }
    return (values.reduce((a, b) => a + b) / values.length).round();
  }
}

ShotTimingStatistics calculateShotTimingStatistics(
  Iterable<TrainingSession> sessions,
) {
  return ShotTimingStatistics(
    makeTimesMs: [for (final session in sessions) ...session.makeFlightTimesMs],
    missTimesMs: [for (final session in sessions) ...session.missFlightTimesMs],
  );
}
