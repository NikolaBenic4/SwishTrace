import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/court_zone.dart';
import 'package:tracking_basketball_score_app/models/quest.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';

void main() {
  test('returns three daily and three weekly quests', () {
    final quests = calculateQuests(const [], now: DateTime(2026, 6, 22));

    expect(quests.where((quest) => quest.type == 'Daily'), hasLength(3));
    expect(quests.where((quest) => quest.type == 'Weekly'), hasLength(3));
    expect(quests.map((quest) => quest.id).toSet(), hasLength(6));
  });

  test('daily quests rotate tomorrow while weekly quests stay stable', () {
    final monday = calculateQuests(const [], now: DateTime(2026, 6, 22));
    final tuesday = calculateQuests(const [], now: DateTime(2026, 6, 23));

    expect(_ids(monday, 'Daily'), isNot(equals(_ids(tuesday, 'Daily'))));
    expect(_ids(monday, 'Weekly'), equals(_ids(tuesday, 'Weekly')));
  });

  test('weekly quests rotate on Monday', () {
    final sunday = calculateQuests(const [], now: DateTime(2026, 6, 28));
    final monday = calculateQuests(const [], now: DateTime(2026, 6, 29));

    expect(_ids(sunday, 'Weekly'), isNot(equals(_ids(monday, 'Weekly'))));
  });

  test('rotated quests use saved session metrics', () {
    final quests = <Quest>[];
    for (var day = 22; day <= 29; day++) {
      final date = DateTime(2026, 6, day);
      final sessions = [
        _session(
          'one-$day',
          DateTime(2026, 6, day, 10),
          makes: 14,
          misses: 6,
          durationSeconds: 600,
          courtZone: CourtZone.leftWing,
          distanceMeters: 6.75,
          timedShots: 10,
        ),
        _session(
          'two-$day',
          DateTime(2026, 6, day, 18),
          makes: 10,
          misses: 10,
          durationSeconds: 900,
          courtZone: CourtZone.rightWing,
          distanceMeters: 6.75,
          timedShots: 8,
        ),
      ];
      quests.addAll(
        calculateQuests(
          sessions,
          now: date,
        ).where((quest) => quest.type == 'Daily'),
      );
    }

    expect(_quest(quests, 'daily-makes-15').current, 24);
    expect(_quest(quests, 'daily-attempts-30').current, 40);
    expect(_quest(quests, 'daily-minutes-15').current, 25);
    expect(_quest(quests, 'daily-accuracy-60').current, 60);
    expect(_quest(quests, 'daily-accuracy-60').qualifierCurrent, 40);
    expect(_quest(quests, 'daily-zones-2').current, 2);
    expect(_quest(quests, 'daily-calibrated-20').current, 40);
    expect(_quest(quests, 'daily-timed-12').current, 18);
  });

  test('accuracy quest requires both percentage and attempt volume', () {
    const quest = Quest(
      id: 'accuracy',
      type: 'Daily',
      title: 'Shoot 60% across 20 attempts',
      current: 80,
      target: 60,
      qualifierCurrent: 10,
      qualifierTarget: 20,
      qualifierLabel: 'attempts',
      rewardPoints: 100,
      reward: '+100 pts',
    );

    expect(quest.progress, 0.5);
    expect(quest.isComplete, isFalse);
    expect(quest.statusLabel, '60 / 60 • 10 / 20 attempts');
  });

  test('caps progress and status labels when a quest is complete', () {
    const quest = Quest(
      id: 'makes',
      type: 'Daily',
      title: 'Make 15 shots today',
      current: 31,
      target: 15,
      rewardPoints: 70,
      reward: '+70 pts',
    );

    expect(quest.progress, 1);
    expect(quest.isComplete, isTrue);
    expect(quest.statusLabel, '15 / 15');
  });
}

Set<String> _ids(List<Quest> quests, String type) {
  return quests
      .where((quest) => quest.type == type)
      .map((quest) => quest.id)
      .toSet();
}

Quest _quest(List<Quest> quests, String id) {
  return quests.firstWhere((quest) => quest.id == id);
}

TrainingSession _session(
  String id,
  DateTime endedAt, {
  required int makes,
  required int misses,
  required int durationSeconds,
  required CourtZone courtZone,
  required double distanceMeters,
  required int timedShots,
}) {
  return TrainingSession(
    id: id,
    modeTitle: 'Live Shot Tracking',
    startedAt: endedAt.subtract(Duration(seconds: durationSeconds)),
    endedAt: endedAt,
    makes: makes,
    misses: misses,
    durationSeconds: durationSeconds,
    courtZone: courtZone,
    distanceMeters: distanceMeters,
    makeFlightTimesMs: List.filled(timedShots, 500),
  );
}
