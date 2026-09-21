import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/court_zone.dart';
import 'package:tracking_basketball_score_app/models/shot_chart_entry.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';
import 'package:tracking_basketball_score_app/models/zone_statistics.dart';

void main() {
  test('aggregates makes and attempts by assigned court zone', () {
    final sessions = [
      _session(CourtZone.leftWing, makes: 4, misses: 2),
      _session(CourtZone.leftWing, makes: 2, misses: 2),
      _session(CourtZone.paint, makes: 5, misses: 0),
      _session(null, makes: 10, misses: 10),
    ];

    final statistics = calculateZoneStatistics(sessions);
    final leftWing = statistics.singleWhere(
      (item) => item.zone == CourtZone.leftWing,
    );
    final paint = statistics.singleWhere(
      (item) => item.zone == CourtZone.paint,
    );

    expect(leftWing.makes, 6);
    expect(leftWing.attempts, 10);
    expect(leftWing.percentage, 60);
    expect(paint.percentage, 100);
  });

  test('uses precise shot positions when a shot chart is available', () {
    final session = TrainingSession(
      id: 'mapped',
      modeTitle: 'Live Shot Tracking',
      startedAt: DateTime.utc(2026, 6, 22),
      endedAt: DateTime.utc(2026, 6, 22, 0, 10),
      makes: 1,
      misses: 1,
      durationSeconds: 600,
      courtZone: CourtZone.top,
      shotChart: [
        ShotChartEntry(
          x: 0.15,
          y: 0.75,
          made: true,
          capturedAt: DateTime.utc(2026, 6, 22, 0, 2),
        ),
        ShotChartEntry(
          x: 0.85,
          y: 0.75,
          made: false,
          capturedAt: DateTime.utc(2026, 6, 22, 0, 3),
        ),
      ],
    );

    final statistics = calculateZoneStatistics([session]);
    final left = statistics.singleWhere(
      (item) => item.zone == CourtZone.leftWing,
    );
    final right = statistics.singleWhere(
      (item) => item.zone == CourtZone.rightWing,
    );
    final top = statistics.singleWhere((item) => item.zone == CourtZone.top);

    expect(left.makes, 1);
    expect(left.attempts, 1);
    expect(right.makes, 0);
    expect(right.attempts, 1);
    expect(top.attempts, 0);
  });
}

TrainingSession _session(
  CourtZone? courtZone, {
  required int makes,
  required int misses,
}) {
  final endedAt = DateTime.utc(2026, 6, 16);
  return TrainingSession(
    id: '${courtZone?.name}-$makes-$misses',
    modeTitle: 'Live Shot Tracking',
    startedAt: endedAt.subtract(const Duration(minutes: 5)),
    endedAt: endedAt,
    makes: makes,
    misses: misses,
    durationSeconds: 300,
    courtZone: courtZone,
  );
}
