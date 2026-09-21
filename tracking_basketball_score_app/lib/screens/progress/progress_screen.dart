import 'package:flutter/material.dart';

import '../../models/shot_timing_statistics.dart';
import '../../models/training_session.dart';
import '../../models/weak_zone_drill_recommendation.dart';
import '../../models/zone_statistics.dart';
import '../../services/session_storage.dart';
import '../../widgets/half_court_shot_chart.dart';
import 'widgets/insight_row.dart';
import 'widgets/zone_progress.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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
        final statistics = calculateZoneStatistics(sessions);
        final timing = calculateShotTimingStatistics(sessions);
        final recommendation = recommendWeakZoneDrill(statistics);
        final diagnosticSession = sessions
            .where((session) => session.processedDetectionFrames > 0)
            .firstOrNull;
        final assignedAttempts = statistics.fold(
          0,
          (total, zone) => total + zone.attempts,
        );
        final chartShots = [
          for (final session in sessions) ...session.shotChart,
        ];

        return RefreshIndicator(
          onRefresh: _reloadSessions,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shot chart',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chartShots.isEmpty
                            ? 'Use Distance Challenge to map shooting spots.'
                            : '${chartShots.length} precisely mapped shots',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      HalfCourtShotChart(shots: chartShots),
                      const SizedBox(height: 10),
                      const ShotChartLegend(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shot percentage by zone',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignedAttempts == 0
                            ? 'Assign a zone when saving your next session.'
                            : '$assignedAttempts tracked shots with a court zone',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      for (final zone in statistics)
                        ZoneProgress(
                          zone: zone.zone.label,
                          pct: zone.percentage,
                          makes: zone.makes,
                          attempts: zone.attempts,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DrillRecommendationCard(
                recommendation: recommendation,
                assignedAttempts: assignedAttempts,
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tracked flight timing',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timing.trackedShots == 0
                            ? 'Timing appears after newly tracked shots.'
                            : '${timing.trackedShots} shots with trajectory timing',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      _TimingRow(
                        icon: Icons.check_circle_outline,
                        label: 'Makes',
                        value: _timingLabel(timing.averageMakeMs),
                      ),
                      _TimingRow(
                        icon: Icons.cancel_outlined,
                        label: 'Misses',
                        value: _timingLabel(timing.averageMissMs),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DetectionHealthCard(session: diagnosticSession),
              const SizedBox(height: 12),
              const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next insight targets',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      InsightRow(
                        icon: Icons.accessibility_new,
                        text:
                            'Add pose keypoints for true hand-release timing.',
                      ),
                      InsightRow(
                        icon: Icons.timeline,
                        text: 'Measure distance with phone calibration.',
                      ),
                      InsightRow(
                        icon: Icons.bolt_outlined,
                        text: 'Detect streak fatigue after 40 attempts.',
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

  String _timingLabel(int? milliseconds) {
    return milliseconds == null ? '--' : '$milliseconds ms average';
  }
}

class _DetectionHealthCard extends StatelessWidget {
  const _DetectionHealthCard({required this.session});

  final TrainingSession? session;

  @override
  Widget build(BuildContext context) {
    final session = this.session;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest detection health',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              session == null
                  ? 'Save a live tracking session to capture diagnostics.'
                  : '${session.processedDetectionFrames} processed frames',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            _TimingRow(
              icon: Icons.speed,
              label: 'Average inference',
              value: session?.averageInferenceTimeMs == null
                  ? '--'
                  : '${session!.averageInferenceTimeMs} ms',
            ),
            _TimingRow(
              icon: Icons.sports_basketball,
              label: 'Ball visibility',
              value: session == null
                  ? '--'
                  : '${session.ballVisibilityPercentage}%',
            ),
            _TimingRow(
              icon: Icons.sports_basketball_outlined,
              label: 'Rim visibility',
              value: session == null
                  ? '--'
                  : '${session.rimVisibilityPercentage}%',
            ),
            _TimingRow(
              icon: Icons.person_outline,
              label: 'Player visibility',
              value: session == null
                  ? '--'
                  : '${session.playerVisibilityPercentage}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _DrillRecommendationCard extends StatelessWidget {
  const _DrillRecommendationCard({
    required this.recommendation,
    required this.assignedAttempts,
  });

  final WeakZoneDrillRecommendation? recommendation;
  final int assignedAttempts;

  @override
  Widget build(BuildContext context) {
    final recommendation = this.recommendation;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended drill',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              recommendation == null
                  ? assignedAttempts == 0
                        ? 'Track a session with a court zone to unlock this.'
                        : 'Track at least 5 attempts in a zone for a reliable drill.'
                  : '${recommendation.zone.label}: '
                        '${recommendation.makes}/${recommendation.attempts} '
                        '(${recommendation.percentage}%)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            if (recommendation == null) ...[
              const InsightRow(
                icon: Icons.add_location_alt_outlined,
                text: 'Choose a court zone before finishing each session.',
              ),
              const InsightRow(
                icon: Icons.sports_basketball_outlined,
                text: 'Save makes and misses from the same zone.',
              ),
            ] else ...[
              Text(
                recommendation.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              InsightRow(
                icon: Icons.center_focus_strong,
                text: recommendation.focus,
              ),
              InsightRow(
                icon: Icons.fitness_center,
                text: recommendation.drill,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
