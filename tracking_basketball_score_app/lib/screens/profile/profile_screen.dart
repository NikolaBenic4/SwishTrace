import 'package:flutter/material.dart';

import '../../models/online_models.dart';
import '../../models/player_rewards.dart';
import '../../models/profile_statistics.dart';
import '../../models/quest.dart';
import '../../models/training_session.dart';
import '../../services/account_storage.dart';
import '../../services/session_storage.dart';
import '../../widgets/half_court_shot_chart.dart';
import '../social/social_screen.dart';
import '../session_detail/session_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _sessionStorage = SessionStorage();
  final _accountStorage = AccountStorage();
  late Future<_ProfileData> _data = _load();

  Future<_ProfileData> _load() async {
    final results = await Future.wait<Object?>([
      _sessionStorage.loadSessions(),
      _accountStorage.load(),
    ]);
    final sessions = results[0]! as List<TrainingSession>;
    final account = results[1] as ShotLabAccount?;
    final quests = calculateQuests(sessions);
    return _ProfileData(
      sessions: sessions,
      account: account,
      statistics: calculateProfileStatistics(sessions),
      rewards: calculatePlayerRewards(sessions, quests),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<_ProfileData>(
        future: _data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _data = _load());
              await _data;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _ProfileHero(data: data, onOpenAccount: _openAccount),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Overall statistics',
                  child: _StatGrid(
                    children: [
                      _ProfileStat(
                        label: 'Sessions',
                        value: '${data.statistics.sessions}',
                        icon: Icons.calendar_month_outlined,
                      ),
                      _ProfileStat(
                        label: 'Makes',
                        value: '${data.statistics.makes}',
                        icon: Icons.sports_basketball,
                      ),
                      _ProfileStat(
                        label: 'Attempts',
                        value: '${data.statistics.attempts}',
                        icon: Icons.track_changes,
                      ),
                      _ProfileStat(
                        label: 'Accuracy',
                        value: '${data.statistics.percentage}%',
                        icon: Icons.percent,
                      ),
                      _ProfileStat(
                        label: 'Training',
                        value: _minutesLabel(data.statistics.trainingMinutes),
                        icon: Icons.timer_outlined,
                      ),
                      _ProfileStat(
                        label: 'Active days',
                        value: '${data.statistics.activeDays}',
                        icon: Icons.event_available_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Personal records',
                  child: Column(
                    children: [
                      _RecordRow(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Current training streak',
                        value: '${data.statistics.currentStreakDays} days',
                      ),
                      _RecordRow(
                        icon: Icons.emoji_events_outlined,
                        label: 'Most makes in one session',
                        value: '${data.statistics.bestSessionMakes}',
                      ),
                      _RecordRow(
                        icon: Icons.bolt_outlined,
                        label: 'Best accuracy over 10+ shots',
                        value: '${data.statistics.bestSessionPercentage}%',
                      ),
                      _RecordRow(
                        icon: Icons.schedule,
                        label: 'Longest session',
                        value:
                            '${data.statistics.longestSessionMinutes} minutes',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Tracking coverage',
                  child: _StatGrid(
                    children: [
                      _ProfileStat(
                        label: 'Court zones',
                        value: '${data.statistics.zonesCovered} / 7',
                        icon: Icons.location_on_outlined,
                      ),
                      _ProfileStat(
                        label: 'Trajectories',
                        value: '${data.statistics.trackedTrajectories}',
                        icon: Icons.timeline,
                      ),
                      _ProfileStat(
                        label: 'Avg distance',
                        value: _distanceLabel(
                          data.statistics.averageDistanceMeters,
                        ),
                        icon: Icons.straighten,
                      ),
                      _ProfileStat(
                        label: 'Farthest',
                        value: _distanceLabel(
                          data.statistics.farthestDistanceMeters,
                        ),
                        icon: Icons.radar,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Lifetime shot chart',
                  child: Column(
                    children: [
                      HalfCourtShotChart(
                        shots: [
                          for (final session in data.sessions)
                            ...session.shotChart,
                        ],
                      ),
                      const SizedBox(height: 10),
                      const ShotChartLegend(),
                      if (data.sessions.every(
                        (session) => session.shotChart.isEmpty,
                      )) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Use Distance Challenge to record precise shooting spots.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _AchievementsCard(statistics: data.statistics),
                const SizedBox(height: 12),
                _RecentSessionsCard(
                  sessions: data.sessions.take(5).toList(),
                  onReviewSession: _reviewSession,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAccount() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SocialScreen()));
    if (mounted) setState(() => _data = _load());
  }

  void _reviewSession(TrainingSession session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionDetailScreen(session: session),
      ),
    );
  }

  String _minutesLabel(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  String _distanceLabel(double? meters) {
    return meters == null ? '--' : '${meters.toStringAsFixed(2)} m';
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.data, required this.onOpenAccount});

  final _ProfileData data;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              data.account?.email.substring(0, 1).toUpperCase() ?? 'P',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.account?.email ?? 'Local player',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${data.rewards.level} • ${data.rewards.points} points',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.statistics.unlockedAchievements} of '
                  '${data.statistics.achievements.length} achievements',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: data.account == null ? 'Sign in' : 'Online account',
            onPressed: onOpenAccount,
            color: Colors.white,
            icon: Icon(
              data.account == null ? Icons.login : Icons.cloud_done_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              key: ValueKey('profile-section-$title'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 280 ? 1 : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 78,
          ),
          itemCount: children.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard({required this.statistics});

  final ProfileStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title:
          'Achievements (${statistics.unlockedAchievements}/${statistics.achievements.length})',
      child: Column(
        children: [
          for (final achievement in statistics.achievements)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: achievement.isUnlocked
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.06),
                    child: Icon(
                      achievement.isUnlocked
                          ? Icons.emoji_events
                          : Icons.lock_outline,
                      color: achievement.isUnlocked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black38,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          achievement.description,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    achievement.isUnlocked
                        ? 'Unlocked'
                        : achievement.progressLabel,
                    style: TextStyle(
                      color: achievement.isUnlocked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black54,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({
    required this.sessions,
    required this.onReviewSession,
  });

  final List<TrainingSession> sessions;
  final ValueChanged<TrainingSession> onReviewSession;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent activity',
      child: sessions.isEmpty
          ? const Text('Your saved workouts will appear here.')
          : Column(
              children: [
                for (final session in sessions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onReviewSession(session),
                    leading: const Icon(Icons.sports_basketball_outlined),
                    title: Text(
                      '${session.makes}/${session.attempts} • '
                      '${session.percentage}%',
                    ),
                    subtitle: Text(
                      '${session.courtZone?.label ?? 'No zone'} • '
                      '${_dateLabel(session.endedAt.toLocal())}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
              ],
            ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _ProfileData {
  const _ProfileData({
    required this.sessions,
    required this.account,
    required this.statistics,
    required this.rewards,
  });

  final List<TrainingSession> sessions;
  final ShotLabAccount? account;
  final ProfileStatistics statistics;
  final PlayerRewards rewards;
}
