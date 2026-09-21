import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/player_rewards.dart';
import 'package:tracking_basketball_score_app/models/quest.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';

void main() {
  test('calculates points from sessions and completed quests', () {
    final rewards = calculatePlayerRewards(
      [
        _session('one', makes: 20, misses: 10),
        _session('two', makes: 15, misses: 5),
      ],
      [
        const Quest(
          id: 'daily-makes',
          type: 'Daily',
          title: 'Make 25 shots today',
          current: 35,
          target: 25,
          rewardPoints: 120,
          reward: '+120 pts',
        ),
        const Quest(
          id: 'weekly-makes',
          type: 'Weekly',
          title: 'Make 150 shots this week',
          current: 35,
          target: 150,
          rewardPoints: 650,
          reward: '+650 pts',
        ),
      ],
    );

    expect(rewards.points, 240);
    expect(rewards.level, 1);
    expect(rewards.pointsToNextLevel, 260);
    expect(rewards.nextUnlock?.title, 'Custom workout slot');
  });

  test('unlocks badges from lifetime milestones', () {
    final sessions = [
      for (var index = 0; index < 10; index++)
        _session('session-$index', makes: 10, misses: 15),
    ];

    final rewards = calculatePlayerRewards(sessions, const []);
    final badges = {for (final badge in rewards.badges) badge.title: badge};

    expect(badges['First run']?.isUnlocked, isTrue);
    expect(badges['Shot maker']?.isUnlocked, isTrue);
    expect(badges['Volume shooter']?.isUnlocked, isTrue);
    expect(badges['Routine builder']?.isUnlocked, isTrue);
  });
}

TrainingSession _session(String id, {required int makes, required int misses}) {
  final endedAt = DateTime.utc(2026, 6, 16);
  return TrainingSession(
    id: id,
    modeTitle: 'Live Shot Tracking',
    startedAt: endedAt.subtract(const Duration(minutes: 5)),
    endedAt: endedAt,
    makes: makes,
    misses: misses,
    durationSeconds: 300,
  );
}
