import 'training_level.dart';

class LevelProgress {
  const LevelProgress({
    required this.currentLevel,
    required this.hearts,
    required this.attemptsUsedToday,
    required this.lastActivityDate,
    required this.starsByLevel,
  });

  factory LevelProgress.initial() {
    return LevelProgress(
      currentLevel: 1,
      hearts: 3,
      attemptsUsedToday: 0,
      lastActivityDate: _today(),
      starsByLevel: const {},
    );
  }

  factory LevelProgress.fromJson(Map<String, Object?> json) {
    final rawStars = json['starsByLevel'];
    final stars = <int, int>{};
    if (rawStars is Map) {
      for (final entry in rawStars.entries) {
        final level = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (level != null && value is num) {
          stars[level] = value.toInt().clamp(0, 3);
        }
      }
    }
    return LevelProgress(
      currentLevel:
          (json['currentLevel'] as num?)?.toInt().clamp(
            1,
            levelCatalog.length + 1,
          ) ??
          1,
      hearts: (json['hearts'] as num?)?.toInt().clamp(0, 3) ?? 3,
      attemptsUsedToday:
          (json['attemptsUsedToday'] as num?)?.toInt().clamp(0, 3) ?? 0,
      lastActivityDate: json['lastActivityDate'] as String? ?? _today(),
      starsByLevel: stars,
    ).forToday();
  }

  final int currentLevel;
  final int hearts;
  final int attemptsUsedToday;
  final String lastActivityDate;
  final Map<int, int> starsByLevel;

  int get remainingAttempts => 3 - attemptsUsedToday;
  bool get hasAttemptLeft => hearts > 0 && attemptsUsedToday < 3;
  bool get isComplete => currentLevel > levelCatalog.length;

  int starsFor(int level) => starsByLevel[level] ?? 0;

  LevelProgress forToday() {
    if (lastActivityDate == _today()) return this;
    return LevelProgress(
      currentLevel: currentLevel,
      hearts: 3,
      attemptsUsedToday: 0,
      lastActivityDate: _today(),
      starsByLevel: starsByLevel,
    );
  }

  LevelProgress applyResult(TrainingLevel level, LevelResult result) {
    final updatedStars = Map<int, int>.from(starsByLevel);
    if (result.passed) {
      updatedStars[level.number] = (updatedStars[level.number] ?? 0).clamp(
        result.stars,
        3,
      );
    }
    final nextLevel = result.passed && level.number == currentLevel
        ? (currentLevel + 1).clamp(1, levelCatalog.length + 1)
        : currentLevel;
    final earnedHeart = result.passed && result.stars == 3;
    return LevelProgress(
      currentLevel: nextLevel,
      hearts: earnedHeart ? (hearts + 1).clamp(0, 3) : (hearts - 1).clamp(0, 3),
      attemptsUsedToday: attemptsUsedToday + 1,
      lastActivityDate: _today(),
      starsByLevel: updatedStars,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'currentLevel': currentLevel,
      'hearts': hearts,
      'attemptsUsedToday': attemptsUsedToday,
      'lastActivityDate': lastActivityDate,
      'starsByLevel': {
        for (final entry in starsByLevel.entries) '${entry.key}': entry.value,
      },
    };
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
