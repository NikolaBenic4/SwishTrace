import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/court_zone.dart';
import 'package:tracking_basketball_score_app/models/profile_statistics.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';

void main() {
  test('calculates lifetime totals, records, streak, and coverage', () {
    final statistics = calculateProfileStatistics([
      _session(
        'one',
        DateTime(2026, 6, 20),
        makes: 8,
        misses: 2,
        minutes: 12,
        zone: CourtZone.leftWing,
        distance: 6.75,
        trajectories: 10,
      ),
      _session(
        'two',
        DateTime(2026, 6, 21),
        makes: 15,
        misses: 5,
        minutes: 20,
        zone: CourtZone.top,
        distance: 7.24,
        trajectories: 12,
      ),
      _session(
        'three',
        DateTime(2026, 6, 22),
        makes: 9,
        misses: 1,
        minutes: 8,
        zone: CourtZone.paint,
        distance: null,
        trajectories: 8,
      ),
    ], now: DateTime(2026, 6, 22, 18));

    expect(statistics.sessions, 3);
    expect(statistics.makes, 32);
    expect(statistics.attempts, 40);
    expect(statistics.percentage, 80);
    expect(statistics.trainingMinutes, 40);
    expect(statistics.activeDays, 3);
    expect(statistics.currentStreakDays, 3);
    expect(statistics.bestSessionMakes, 15);
    expect(statistics.bestSessionPercentage, 90);
    expect(statistics.longestSessionMinutes, 20);
    expect(statistics.averageDistanceMeters, closeTo(6.995, 0.001));
    expect(statistics.farthestDistanceMeters, 7.24);
    expect(statistics.zonesCovered, 3);
    expect(statistics.trackedTrajectories, 30);
    expect(statistics.achievements, hasLength(23));
    expect(
      statistics.achievements
          .singleWhere((item) => item.id == 'three-day-streak')
          .isUnlocked,
      isTrue,
    );
  });

  test('unlocks achievements when their requirement is met', () {
    final statistics = calculateProfileStatistics([
      _session(
        'hot',
        DateTime(2026, 6, 22),
        makes: 10,
        misses: 0,
        minutes: 10,
        zone: CourtZone.top,
        distance: 6.75,
        trajectories: 10,
      ),
    ], now: DateTime(2026, 6, 22));
    final achievements = {
      for (final item in statistics.achievements) item.id: item,
    };

    expect(achievements['first-bucket']?.isUnlocked, isTrue);
    expect(achievements['hot-session']?.isUnlocked, isTrue);
    expect(achievements['perfect-session']?.isUnlocked, isTrue);
    expect(achievements['century-club']?.isUnlocked, isFalse);
  });
}

TrainingSession _session(
  String id,
  DateTime endedAt, {
  required int makes,
  required int misses,
  required int minutes,
  required CourtZone zone,
  required double? distance,
  required int trajectories,
}) {
  return TrainingSession(
    id: id,
    modeTitle: 'Live Shot Tracking',
    startedAt: endedAt.subtract(Duration(minutes: minutes)),
    endedAt: endedAt,
    makes: makes,
    misses: misses,
    durationSeconds: minutes * 60,
    courtZone: zone,
    distanceMeters: distance,
    makeFlightTimesMs: List.filled(trajectories, 500),
  );
}
