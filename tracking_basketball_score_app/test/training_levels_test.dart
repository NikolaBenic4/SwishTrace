import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_basketball_score_app/models/level_progress.dart';
import 'package:tracking_basketball_score_app/models/training_level.dart';
import 'package:tracking_basketball_score_app/services/level_progress_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('level one awards three, two, and one star by misses', () {
    final level = levelCatalog.first;

    expect(level.score(makes: 3, misses: 0, bestStreak: 3).stars, 3);
    expect(level.score(makes: 3, misses: 2, bestStreak: 3).stars, 2);
    expect(level.score(makes: 3, misses: 3, bestStreak: 3).stars, 1);
    expect(level.score(makes: 2, misses: 8, bestStreak: 2).passed, isFalse);
  });

  test('level ten requires five free throws in a row', () {
    final level = levelCatalog[9];

    expect(level.type, TrainingLevelType.freeThrows);
    expect(level.score(makes: 5, misses: 2, bestStreak: 5).passed, isTrue);
    expect(level.score(makes: 5, misses: 2, bestStreak: 4).passed, isFalse);
  });

  test('perfect result restores one heart and unlocks the next level', () {
    final progress = LevelProgress.initial().applyResult(
      levelCatalog.first,
      levelCatalog.first.score(makes: 3, misses: 0, bestStreak: 3),
    );

    expect(progress.currentLevel, 2);
    expect(progress.attemptsUsedToday, 1);
    expect(progress.hearts, 3);
    expect(progress.starsFor(1), 3);
  });

  test('level progress persists through shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LevelProgressStorage();
    final progress = LevelProgress.initial().applyResult(
      levelCatalog.first,
      levelCatalog.first.score(makes: 3, misses: 1, bestStreak: 3),
    );

    await storage.saveProgress(progress);
    final restored = await storage.loadProgress();

    expect(restored.currentLevel, 2);
    expect(restored.starsFor(1), 2);
    expect(restored.attemptsUsedToday, 1);
  });
}
