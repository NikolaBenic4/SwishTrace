import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/shot_timing_statistics.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';

void main() {
  test('calculates weighted timing averages from individual shots', () {
    final statistics = calculateShotTimingStatistics([
      _session(makeTimes: [400, 600], missTimes: [700]),
      _session(makeTimes: [500], missTimes: [900, 800]),
    ]);

    expect(statistics.averageMakeMs, 500);
    expect(statistics.averageMissMs, 800);
    expect(statistics.trackedShots, 6);
  });

  test('returns null averages when no timing data exists', () {
    final statistics = calculateShotTimingStatistics([_session()]);

    expect(statistics.averageMakeMs, isNull);
    expect(statistics.averageMissMs, isNull);
  });
}

TrainingSession _session({
  List<int> makeTimes = const [],
  List<int> missTimes = const [],
}) {
  final endedAt = DateTime.utc(2026, 6, 16);
  return TrainingSession(
    id: 'session-${makeTimes.length}-${missTimes.length}',
    modeTitle: 'Live Shot Tracking',
    startedAt: endedAt.subtract(const Duration(minutes: 5)),
    endedAt: endedAt,
    makes: makeTimes.length,
    misses: missTimes.length,
    durationSeconds: 300,
    makeFlightTimesMs: makeTimes,
    missFlightTimesMs: missTimes,
  );
}
