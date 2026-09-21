import 'package:flutter/material.dart';

import '../../models/shot_chart_entry.dart';
import '../../models/training_session.dart';
import '../../widgets/half_court_shot_chart.dart';

enum ShotChartFilter { all, makes, misses }

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({required this.session, super.key});

  final TrainingSession session;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  ShotChartFilter _filter = ShotChartFilter.all;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final filteredShots = _filteredShots(session.shotChart);

    return Scaffold(
      appBar: AppBar(title: const Text('Session review')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Text(
            session.modeTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            _dateLabel(session.endedAt.toLocal()),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          _SessionScoreCard(session: session),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shot locations',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.shotChart.isEmpty
                        ? 'This session has no precise shot positions.'
                        : '${filteredShots.length} of '
                              '${session.shotChart.length} shots shown',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ShotChartFilter>(
                    segments: const [
                      ButtonSegment(
                        value: ShotChartFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: ShotChartFilter.makes,
                        label: Text('Makes'),
                      ),
                      ButtonSegment(
                        value: ShotChartFilter.misses,
                        label: Text('Misses'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) {
                      setState(() => _filter = selection.single);
                    },
                  ),
                  const SizedBox(height: 14),
                  HalfCourtShotChart(shots: filteredShots),
                  const SizedBox(height: 10),
                  const ShotChartLegend(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SessionDetailsCard(session: session),
        ],
      ),
    );
  }

  List<ShotChartEntry> _filteredShots(List<ShotChartEntry> shots) {
    return switch (_filter) {
      ShotChartFilter.all => shots,
      ShotChartFilter.makes => shots.where((shot) => shot.made).toList(),
      ShotChartFilter.misses => shots.where((shot) => !shot.made).toList(),
    };
  }

  String _dateLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}.${date.month}.${date.year} at $hour:$minute';
  }
}

class _SessionScoreCard extends StatelessWidget {
  const _SessionScoreCard({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _ScoreValue(label: 'MAKES', value: '${session.makes}'),
          _ScoreValue(label: 'MISSES', value: '${session.misses}'),
          _ScoreValue(label: 'ATTEMPTS', value: '${session.attempts}'),
          _ScoreValue(label: 'ACCURACY', value: '${session.percentage}%'),
        ],
      ),
    );
  }
}

class _ScoreValue extends StatelessWidget {
  const _ScoreValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetailsCard extends StatelessWidget {
  const _SessionDetailsCard({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final trackedTimes = [
      ...session.makeFlightTimesMs,
      ...session.missFlightTimesMs,
    ];
    final averageFlight = trackedTimes.isEmpty
        ? null
        : (trackedTimes.reduce((a, b) => a + b) / trackedTimes.length).round();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session details',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Duration',
              value: _durationLabel(session.durationSeconds),
            ),
            _DetailRow(
              label: 'Court zone',
              value: session.courtZone?.label ?? '--',
            ),
            _DetailRow(
              label: 'Distance',
              value: session.distanceMeters == null
                  ? '--'
                  : '${session.distanceMeters!.toStringAsFixed(2)} m',
            ),
            _DetailRow(
              label: 'Average tracked flight',
              value: averageFlight == null ? '--' : '$averageFlight ms',
            ),
            _DetailRow(
              label: 'Average inference',
              value: session.averageInferenceTimeMs == null
                  ? '--'
                  : '${session.averageInferenceTimeMs} ms',
            ),
            _DetailRow(
              label: 'Detection frames',
              value: '${session.processedDetectionFrames}',
            ),
            _DetailRow(
              label: 'Ball visibility',
              value: _visibilityLabel(
                session.ballVisibleFrames,
                session.processedDetectionFrames,
              ),
            ),
            _DetailRow(
              label: 'Rim visibility',
              value: _visibilityLabel(
                session.rimVisibleFrames,
                session.processedDetectionFrames,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }

  String _visibilityLabel(int visibleFrames, int processedFrames) {
    if (processedFrames == 0) return 'No frames processed';
    return '${(visibleFrames / processedFrames * 100).round()}%';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
