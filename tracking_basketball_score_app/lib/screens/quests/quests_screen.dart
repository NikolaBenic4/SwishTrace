import 'package:flutter/material.dart';

import '../../models/player_rewards.dart';
import '../../models/quest.dart';
import '../../models/training_session.dart';
import '../../services/session_storage.dart';
import 'widgets/quest_card.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  final SessionStorage _sessionStorage = SessionStorage();
  late Future<List<TrainingSession>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = _sessionStorage.loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrainingSession>>(
      future: _sessions,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <TrainingSession>[];
        final rotation = calculateQuestRotation(sessions);
        final quests = rotation.quests;
        final rewards = calculatePlayerRewards(sessions, quests);
        final completed = quests.where((quest) => quest.isComplete).length;

        return RefreshIndicator(
          onRefresh: _reloadSessions,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Text(
                'Quests',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sessions.isEmpty
                    ? 'Finish a tracked session to start earning quest progress.'
                    : '$completed of ${quests.length} quests complete',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                '3 daily quests rotate at midnight • 3 weekly quests rotate Monday',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black45),
              ),
              const SizedBox(height: 14),
              _RewardsSummary(rewards: rewards),
              const SizedBox(height: 12),
              for (final quest in quests) ...[
                QuestCard(quest: quest),
                const SizedBox(height: 12),
              ],
              _BadgeProgress(badges: rewards.badges),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_open, color: Color(0xFFE87521)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Points are local for now. Badges, custom workouts, '
                          'and friend challenges unlock after online mode.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reloadSessions() async {
    setState(() {
      _sessions = _sessionStorage.loadSessions();
    });
    await _sessions;
  }
}

class _RewardsSummary extends StatelessWidget {
  const _RewardsSummary({required this.rewards});

  final PlayerRewards rewards;

  @override
  Widget build(BuildContext context) {
    final nextUnlock = rewards.nextUnlock;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: Color(0xFFE87521)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Level ${rewards.level}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${rewards.points} pts',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (500 - rewards.pointsToNextLevel) / 500,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '${rewards.pointsToNextLevel} pts to level ${rewards.level + 1}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            if (nextUnlock != null) ...[
              const SizedBox(height: 12),
              Text(
                nextUnlock.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${nextUnlock.description} Unlocks at level '
                '${nextUnlock.requiredLevel}.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeProgress extends StatelessWidget {
  const _BadgeProgress({required this.badges});

  final List<PlayerBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badges',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            for (final badge in badges) _BadgeRow(badge: badge),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badge});

  final PlayerBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = badge.isUnlocked
        ? Theme.of(context).colorScheme.primary
        : Colors.black38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            badge.isUnlocked
                ? Icons.verified_outlined
                : Icons.radio_button_unchecked,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            badge.isUnlocked ? 'Unlocked' : badge.progressLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
