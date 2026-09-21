import 'quest.dart';
import 'training_session.dart';

class PlayerRewards {
  const PlayerRewards({
    required this.points,
    required this.level,
    required this.pointsToNextLevel,
    required this.badges,
    required this.nextUnlock,
  });

  final int points;
  final int level;
  final int pointsToNextLevel;
  final List<PlayerBadge> badges;
  final RewardUnlock? nextUnlock;
}

class PlayerBadge {
  const PlayerBadge({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.current,
    required this.target,
  });

  final String title;
  final String description;
  final bool isUnlocked;
  final int current;
  final int target;

  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);
  String get progressLabel => '${current.clamp(0, target)} / $target';
}

class RewardUnlock {
  const RewardUnlock({
    required this.title,
    required this.description,
    required this.requiredLevel,
  });

  final String title;
  final String description;
  final int requiredLevel;
}

PlayerRewards calculatePlayerRewards(
  Iterable<TrainingSession> sessions,
  Iterable<Quest> quests,
) {
  final sessionList = sessions.toList();
  final totalMakes = sessionList.fold(0, (total, item) => total + item.makes);
  final totalAttempts = sessionList.fold(
    0,
    (total, item) => total + item.attempts,
  );
  final completedQuestPoints = quests
      .where((quest) => quest.isComplete)
      .fold(0, (total, quest) => total + quest.rewardPoints);
  final points = totalMakes * 2 + totalAttempts + completedQuestPoints;
  final level = points ~/ 500 + 1;
  final pointsToNextLevel = 500 - points % 500;

  final badges = [
    PlayerBadge(
      title: 'First run',
      description: 'Save your first tracked session.',
      isUnlocked: sessionList.isNotEmpty,
      current: sessionList.length,
      target: 1,
    ),
    PlayerBadge(
      title: 'Shot maker',
      description: 'Make 100 tracked shots.',
      isUnlocked: totalMakes >= 100,
      current: totalMakes,
      target: 100,
    ),
    PlayerBadge(
      title: 'Volume shooter',
      description: 'Track 250 total attempts.',
      isUnlocked: totalAttempts >= 250,
      current: totalAttempts,
      target: 250,
    ),
    PlayerBadge(
      title: 'Routine builder',
      description: 'Save 10 tracked sessions.',
      isUnlocked: sessionList.length >= 10,
      current: sessionList.length,
      target: 10,
    ),
  ];

  return PlayerRewards(
    points: points,
    level: level,
    pointsToNextLevel: pointsToNextLevel,
    badges: badges,
    nextUnlock: _nextUnlockFor(level),
  );
}

RewardUnlock? _nextUnlockFor(int level) {
  const unlocks = [
    RewardUnlock(
      title: 'Custom workout slot',
      description: 'Save a favorite drill plan.',
      requiredLevel: 2,
    ),
    RewardUnlock(
      title: 'Badge showcase',
      description: 'Pin earned badges to your profile.',
      requiredLevel: 3,
    ),
    RewardUnlock(
      title: 'Challenge prep',
      description: 'Preview friend challenge rules before online mode.',
      requiredLevel: 5,
    ),
  ];

  for (final unlock in unlocks) {
    if (level < unlock.requiredLevel) {
      return unlock;
    }
  }
  return null;
}
