import 'dart:math' as math;

import 'training_session.dart';

class Quest {
  const Quest({
    required this.id,
    required this.type,
    required this.title,
    required this.current,
    required this.target,
    required this.rewardPoints,
    required this.reward,
    this.qualifierCurrent,
    this.qualifierTarget,
    this.qualifierLabel,
  });

  final String id;
  final String type;
  final String title;
  final int current;
  final int target;
  final int rewardPoints;
  final String reward;
  final int? qualifierCurrent;
  final int? qualifierTarget;
  final String? qualifierLabel;

  double get progress {
    final primary = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final secondaryTarget = qualifierTarget;
    if (secondaryTarget == null || secondaryTarget == 0) return primary;
    final secondary = ((qualifierCurrent ?? 0) / secondaryTarget).clamp(
      0.0,
      1.0,
    );
    return math.min(primary, secondary);
  }

  bool get isComplete =>
      current >= target &&
      (qualifierTarget == null || (qualifierCurrent ?? 0) >= qualifierTarget!);

  String get statusLabel {
    final primary = '${current.clamp(0, target)} / $target';
    if (qualifierTarget == null) return primary;
    return '$primary • ${(qualifierCurrent ?? 0).clamp(0, qualifierTarget!)}'
            ' / $qualifierTarget ${qualifierLabel ?? ''}'
        .trim();
  }
}

class QuestRotation {
  const QuestRotation({
    required this.quests,
    required this.nextDailyRotation,
    required this.nextWeeklyRotation,
  });

  final List<Quest> quests;
  final DateTime nextDailyRotation;
  final DateTime nextWeeklyRotation;
}

QuestRotation calculateQuestRotation(
  Iterable<TrainingSession> sessions, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final todayStart = DateTime(reference.year, reference.month, reference.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));
  final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
  final nextWeekStart = weekStart.add(const Duration(days: 7));
  final sessionList = sessions.toList();
  final todaySessions = sessionList.where((session) {
    final endedAt = session.endedAt.toLocal();
    return !endedAt.isBefore(todayStart) && endedAt.isBefore(tomorrowStart);
  }).toList();
  final weekSessions = sessionList.where((session) {
    final endedAt = session.endedAt.toLocal();
    return !endedAt.isBefore(weekStart) && endedAt.isBefore(nextWeekStart);
  }).toList();

  final dailyStats = _QuestStats.fromSessions(todaySessions);
  final weeklyStats = _QuestStats.fromSessions(weekSessions);
  final dailySeed = todayStart.difference(DateTime(2026)).inDays;
  final weeklySeed = weekStart.difference(DateTime(2026)).inDays ~/ 7;

  return QuestRotation(
    quests: [
      ..._selectRotating(
        _dailyPool,
        dailySeed,
        3,
      ).map((definition) => definition.build(dailyStats)),
      ..._selectRotating(
        _weeklyPool,
        weeklySeed,
        3,
      ).map((definition) => definition.build(weeklyStats)),
    ],
    nextDailyRotation: tomorrowStart,
    nextWeeklyRotation: nextWeekStart,
  );
}

List<Quest> calculateQuests(
  Iterable<TrainingSession> sessions, {
  DateTime? now,
}) {
  return calculateQuestRotation(sessions, now: now).quests;
}

enum _QuestMetric {
  makes,
  attempts,
  sessions,
  minutes,
  percentage,
  zones,
  calibratedAttempts,
  timedShots,
}

class _QuestDefinition {
  const _QuestDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.metric,
    required this.target,
    required this.rewardPoints,
    this.minimumAttempts,
  });

  final String id;
  final String type;
  final String title;
  final _QuestMetric metric;
  final int target;
  final int rewardPoints;
  final int? minimumAttempts;

  Quest build(_QuestStats stats) {
    return Quest(
      id: id,
      type: type,
      title: title,
      current: stats.value(metric),
      target: target,
      rewardPoints: rewardPoints,
      reward: '+$rewardPoints pts',
      qualifierCurrent: minimumAttempts == null ? null : stats.attempts,
      qualifierTarget: minimumAttempts,
      qualifierLabel: minimumAttempts == null ? null : 'attempts',
    );
  }
}

class _QuestStats {
  const _QuestStats({
    required this.makes,
    required this.attempts,
    required this.sessions,
    required this.minutes,
    required this.percentage,
    required this.zones,
    required this.calibratedAttempts,
    required this.timedShots,
  });

  factory _QuestStats.fromSessions(List<TrainingSession> sessions) {
    final makes = sessions.fold(0, (total, item) => total + item.makes);
    final attempts = sessions.fold(0, (total, item) => total + item.attempts);
    return _QuestStats(
      makes: makes,
      attempts: attempts,
      sessions: sessions.length,
      minutes:
          sessions.fold(0, (total, item) => total + item.durationSeconds) ~/ 60,
      percentage: attempts == 0 ? 0 : (makes / attempts * 100).round(),
      zones: sessions.map((item) => item.courtZone).nonNulls.toSet().length,
      calibratedAttempts: sessions
          .where((item) => item.distanceMeters != null)
          .fold(0, (total, item) => total + item.attempts),
      timedShots: sessions.fold(
        0,
        (total, item) =>
            total +
            item.makeFlightTimesMs.length +
            item.missFlightTimesMs.length,
      ),
    );
  }

  final int makes;
  final int attempts;
  final int sessions;
  final int minutes;
  final int percentage;
  final int zones;
  final int calibratedAttempts;
  final int timedShots;

  int value(_QuestMetric metric) => switch (metric) {
    _QuestMetric.makes => makes,
    _QuestMetric.attempts => attempts,
    _QuestMetric.sessions => sessions,
    _QuestMetric.minutes => minutes,
    _QuestMetric.percentage => percentage,
    _QuestMetric.zones => zones,
    _QuestMetric.calibratedAttempts => calibratedAttempts,
    _QuestMetric.timedShots => timedShots,
  };
}

List<_QuestDefinition> _selectRotating(
  List<_QuestDefinition> pool,
  int seed,
  int count,
) {
  final start = seed.abs() % pool.length;
  const stride = 3;
  return [
    for (var index = 0; index < count; index++)
      pool[(start + index * stride) % pool.length],
  ];
}

const _dailyPool = [
  _QuestDefinition(
    id: 'daily-makes-15',
    type: 'Daily',
    title: 'Make 15 shots today',
    metric: _QuestMetric.makes,
    target: 15,
    rewardPoints: 70,
  ),
  _QuestDefinition(
    id: 'daily-attempts-30',
    type: 'Daily',
    title: 'Track 30 attempts today',
    metric: _QuestMetric.attempts,
    target: 30,
    rewardPoints: 60,
  ),
  _QuestDefinition(
    id: 'daily-session-1',
    type: 'Daily',
    title: 'Complete a tracked session',
    metric: _QuestMetric.sessions,
    target: 1,
    rewardPoints: 50,
  ),
  _QuestDefinition(
    id: 'daily-minutes-15',
    type: 'Daily',
    title: 'Train for 15 tracked minutes',
    metric: _QuestMetric.minutes,
    target: 15,
    rewardPoints: 80,
  ),
  _QuestDefinition(
    id: 'daily-accuracy-60',
    type: 'Daily',
    title: 'Shoot 60% across 20 attempts',
    metric: _QuestMetric.percentage,
    target: 60,
    minimumAttempts: 20,
    rewardPoints: 110,
  ),
  _QuestDefinition(
    id: 'daily-zones-2',
    type: 'Daily',
    title: 'Train in 2 court zones',
    metric: _QuestMetric.zones,
    target: 2,
    rewardPoints: 90,
  ),
  _QuestDefinition(
    id: 'daily-calibrated-20',
    type: 'Daily',
    title: 'Track 20 shots with distance set',
    metric: _QuestMetric.calibratedAttempts,
    target: 20,
    rewardPoints: 85,
  ),
  _QuestDefinition(
    id: 'daily-timed-12',
    type: 'Daily',
    title: 'Capture 12 shot trajectories',
    metric: _QuestMetric.timedShots,
    target: 12,
    rewardPoints: 95,
  ),
];

const _weeklyPool = [
  _QuestDefinition(
    id: 'weekly-makes-100',
    type: 'Weekly',
    title: 'Make 100 shots this week',
    metric: _QuestMetric.makes,
    target: 100,
    rewardPoints: 450,
  ),
  _QuestDefinition(
    id: 'weekly-attempts-200',
    type: 'Weekly',
    title: 'Track 200 attempts this week',
    metric: _QuestMetric.attempts,
    target: 200,
    rewardPoints: 400,
  ),
  _QuestDefinition(
    id: 'weekly-sessions-4',
    type: 'Weekly',
    title: 'Complete 4 tracked sessions',
    metric: _QuestMetric.sessions,
    target: 4,
    rewardPoints: 500,
  ),
  _QuestDefinition(
    id: 'weekly-minutes-75',
    type: 'Weekly',
    title: 'Train for 75 tracked minutes',
    metric: _QuestMetric.minutes,
    target: 75,
    rewardPoints: 550,
  ),
  _QuestDefinition(
    id: 'weekly-accuracy-65',
    type: 'Weekly',
    title: 'Shoot 65% across 75 attempts',
    metric: _QuestMetric.percentage,
    target: 65,
    minimumAttempts: 75,
    rewardPoints: 700,
  ),
  _QuestDefinition(
    id: 'weekly-zones-5',
    type: 'Weekly',
    title: 'Train in 5 court zones',
    metric: _QuestMetric.zones,
    target: 5,
    rewardPoints: 600,
  ),
  _QuestDefinition(
    id: 'weekly-calibrated-100',
    type: 'Weekly',
    title: 'Track 100 shots with distance set',
    metric: _QuestMetric.calibratedAttempts,
    target: 100,
    rewardPoints: 575,
  ),
  _QuestDefinition(
    id: 'weekly-timed-60',
    type: 'Weekly',
    title: 'Capture 60 shot trajectories',
    metric: _QuestMetric.timedShots,
    target: 60,
    rewardPoints: 625,
  ),
];
