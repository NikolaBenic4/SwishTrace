import 'court_zone.dart';
import 'training_session.dart';

class ProfileStatistics {
  const ProfileStatistics({
    required this.sessions,
    required this.makes,
    required this.attempts,
    required this.trainingMinutes,
    required this.activeDays,
    required this.currentStreakDays,
    required this.bestSessionMakes,
    required this.bestSessionPercentage,
    required this.longestSessionMinutes,
    required this.averageDistanceMeters,
    required this.farthestDistanceMeters,
    required this.zonesCovered,
    required this.trackedTrajectories,
    required this.achievements,
  });

  final int sessions;
  final int makes;
  final int attempts;
  final int trainingMinutes;
  final int activeDays;
  final int currentStreakDays;
  final int bestSessionMakes;
  final int bestSessionPercentage;
  final int longestSessionMinutes;
  final double? averageDistanceMeters;
  final double? farthestDistanceMeters;
  final int zonesCovered;
  final int trackedTrajectories;
  final List<ProfileAchievement> achievements;

  int get percentage => attempts == 0 ? 0 : (makes / attempts * 100).round();
  int get unlockedAchievements =>
      achievements.where((achievement) => achievement.isUnlocked).length;
}

class ProfileAchievement {
  const ProfileAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final int current;
  final int target;

  bool get isUnlocked => current >= target;
  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);
  String get progressLabel => '${current.clamp(0, target)} / $target';
}

ProfileStatistics calculateProfileStatistics(
  Iterable<TrainingSession> sessions, {
  DateTime? now,
}) {
  final sessionList = sessions.toList();
  final makes = sessionList.fold(0, (total, item) => total + item.makes);
  final attempts = sessionList.fold(0, (total, item) => total + item.attempts);
  final totalSeconds = sessionList.fold(
    0,
    (total, item) => total + item.durationSeconds,
  );
  final activeDates = sessionList.map((item) {
    final date = item.endedAt.toLocal();
    return DateTime(date.year, date.month, date.day);
  }).toSet();
  final calibratedSessions = sessionList
      .where((item) => item.distanceMeters != null)
      .toList();
  final distances = calibratedSessions
      .map((item) => item.distanceMeters!)
      .toList();
  final coveredZones = <CourtZone>{};
  for (final session in sessionList) {
    if (session.shotChart.isNotEmpty) {
      coveredZones.addAll(session.shotChart.map((shot) => shot.zone));
    } else if (session.courtZone != null) {
      coveredZones.add(session.courtZone!);
    }
  }
  final zonesCovered = coveredZones.length;
  final trackedTrajectories = sessionList.fold(
    0,
    (total, item) =>
        total + item.makeFlightTimesMs.length + item.missFlightTimesMs.length,
  );
  final bestSessionMakes = sessionList.fold(
    0,
    (best, item) => item.makes > best ? item.makes : best,
  );
  final eligibleAccuracySessions = sessionList.where(
    (item) => item.attempts >= 10,
  );
  final bestSessionPercentage = eligibleAccuracySessions.fold(
    0,
    (best, item) => item.percentage > best ? item.percentage : best,
  );
  final longestSeconds = sessionList.fold(
    0,
    (best, item) => item.durationSeconds > best ? item.durationSeconds : best,
  );
  final streak = _currentStreak(activeDates, now ?? DateTime.now());
  final longestStreak = _longestStreak(activeDates);
  final trainingMinutes = totalSeconds ~/ 60;
  final calibratedAttempts = calibratedSessions.fold(
    0,
    (total, item) => total + item.attempts,
  );

  final achievements = [
    ProfileAchievement(
      id: 'first-bucket',
      title: 'First bucket',
      description: 'Make your first tracked shot.',
      current: makes,
      target: 1,
    ),
    ProfileAchievement(
      id: 'century-club',
      title: 'Century club',
      description: 'Make 100 tracked shots.',
      current: makes,
      target: 100,
    ),
    ProfileAchievement(
      id: 'five-hundred-makes',
      title: 'Certified scorer',
      description: 'Make 500 tracked shots.',
      current: makes,
      target: 500,
    ),
    ProfileAchievement(
      id: 'one-thousand-makes',
      title: 'Bucket machine',
      description: 'Make 1,000 tracked shots.',
      current: makes,
      target: 1000,
    ),
    ProfileAchievement(
      id: 'first-hundred-attempts',
      title: 'Getting reps',
      description: 'Track 100 total attempts.',
      current: attempts,
      target: 100,
    ),
    ProfileAchievement(
      id: 'high-volume',
      title: 'High volume',
      description: 'Track 500 total attempts.',
      current: attempts,
      target: 500,
    ),
    ProfileAchievement(
      id: 'thousand-attempts',
      title: 'Iron shooter',
      description: 'Track 1,000 total attempts.',
      current: attempts,
      target: 1000,
    ),
    ProfileAchievement(
      id: 'five-sessions',
      title: 'Building a habit',
      description: 'Complete 5 tracked sessions.',
      current: sessionList.length,
      target: 5,
    ),
    ProfileAchievement(
      id: 'gym-regular',
      title: 'Gym regular',
      description: 'Complete 20 tracked sessions.',
      current: sessionList.length,
      target: 20,
    ),
    ProfileAchievement(
      id: 'fifty-sessions',
      title: 'Gym resident',
      description: 'Complete 50 tracked sessions.',
      current: sessionList.length,
      target: 50,
    ),
    ProfileAchievement(
      id: 'three-day-streak',
      title: 'Three-day streak',
      description: 'Train on 3 consecutive days.',
      current: longestStreak,
      target: 3,
    ),
    ProfileAchievement(
      id: 'seven-day-streak',
      title: 'Week warrior',
      description: 'Train on 7 consecutive days.',
      current: longestStreak,
      target: 7,
    ),
    ProfileAchievement(
      id: 'thirty-active-days',
      title: 'Consistent work',
      description: 'Train on 30 different days.',
      current: activeDates.length,
      target: 30,
    ),
    ProfileAchievement(
      id: 'one-hour-training',
      title: 'First hour',
      description: 'Accumulate 60 tracked training minutes.',
      current: trainingMinutes,
      target: 60,
    ),
    ProfileAchievement(
      id: 'ten-hours-training',
      title: 'Ten-hour club',
      description: 'Accumulate 600 tracked training minutes.',
      current: trainingMinutes,
      target: 600,
    ),
    ProfileAchievement(
      id: 'court-explorer',
      title: 'Court explorer',
      description: 'Record shots from all 7 court zones.',
      current: zonesCovered,
      target: CourtZone.values.length,
    ),
    ProfileAchievement(
      id: 'distance-dialed',
      title: 'Distance dialed',
      description: 'Track 100 attempts with distance set.',
      current: calibratedAttempts,
      target: 100,
    ),
    ProfileAchievement(
      id: 'distance-master',
      title: 'Distance master',
      description: 'Track 500 attempts with distance set.',
      current: calibratedAttempts,
      target: 500,
    ),
    ProfileAchievement(
      id: 'trajectory-tech',
      title: 'Trajectory technician',
      description: 'Capture 100 shot trajectories.',
      current: trackedTrajectories,
      target: 100,
    ),
    ProfileAchievement(
      id: 'trajectory-five-hundred',
      title: 'Flight analyst',
      description: 'Capture 500 shot trajectories.',
      current: trackedTrajectories,
      target: 500,
    ),
    ProfileAchievement(
      id: 'hot-session',
      title: 'Hot session',
      description: 'Shoot at least 75% over 10+ attempts.',
      current: bestSessionPercentage,
      target: 75,
    ),
    ProfileAchievement(
      id: 'perfect-session',
      title: 'Perfect ten',
      description: 'Make every shot in a session with 10+ attempts.',
      current: bestSessionPercentage,
      target: 100,
    ),
    ProfileAchievement(
      id: 'twenty-makes-session',
      title: 'Twenty-piece',
      description: 'Make 20 shots in one session.',
      current: bestSessionMakes,
      target: 20,
    ),
  ];

  return ProfileStatistics(
    sessions: sessionList.length,
    makes: makes,
    attempts: attempts,
    trainingMinutes: trainingMinutes,
    activeDays: activeDates.length,
    currentStreakDays: streak,
    bestSessionMakes: bestSessionMakes,
    bestSessionPercentage: bestSessionPercentage,
    longestSessionMinutes: longestSeconds ~/ 60,
    averageDistanceMeters: distances.isEmpty
        ? null
        : distances.reduce((a, b) => a + b) / distances.length,
    farthestDistanceMeters: distances.isEmpty
        ? null
        : distances.reduce((a, b) => a > b ? a : b),
    zonesCovered: zonesCovered,
    trackedTrajectories: trackedTrajectories,
    achievements: achievements,
  );
}

int _currentStreak(Set<DateTime> activeDates, DateTime reference) {
  if (activeDates.isEmpty) return 0;
  final today = DateTime(reference.year, reference.month, reference.day);
  var cursor = activeDates.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  var streak = 0;
  while (activeDates.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int _longestStreak(Set<DateTime> activeDates) {
  if (activeDates.isEmpty) return 0;
  final dates = activeDates.toList()..sort();
  var longest = 1;
  var current = 1;
  for (var index = 1; index < dates.length; index++) {
    if (dates[index].difference(dates[index - 1]).inDays == 1) {
      current += 1;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}
