import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/court_zone.dart';
import 'package:tracking_basketball_score_app/models/shot_chart_entry.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';

void main() {
  test('serializes a complete training session', () {
    final session = TrainingSession(
      id: 'session-1',
      modeTitle: 'Live Shot Tracking',
      startedAt: DateTime.utc(2026, 6, 15, 18),
      endedAt: DateTime.utc(2026, 6, 15, 18, 10),
      makes: 12,
      misses: 8,
      durationSeconds: 600,
      distanceMeters: 6.75,
      courtZone: CourtZone.rightWing,
      makeFlightTimesMs: [450, 500],
      missFlightTimesMs: [620],
      processedDetectionFrames: 20,
      totalInferenceTimeMs: 6400,
      ballVisibleFrames: 18,
      rimVisibleFrames: 20,
      playerVisibleFrames: 19,
      shotChart: [
        ShotChartEntry(
          x: 0.2,
          y: 0.7,
          made: true,
          capturedAt: DateTime.utc(2026, 6, 15, 18, 2),
          trackedFlightTimeMs: 450,
        ),
      ],
    );

    final restored = TrainingSession.fromJson(session.toJson());

    expect(restored.id, session.id);
    expect(restored.attempts, 20);
    expect(restored.percentage, 60);
    expect(restored.distanceMeters, 6.75);
    expect(restored.courtZone, CourtZone.rightWing);
    expect(restored.makeFlightTimesMs, [450, 500]);
    expect(restored.missFlightTimesMs, [620]);
    expect(restored.averageInferenceTimeMs, 320);
    expect(restored.ballVisibilityPercentage, 90);
    expect(restored.rimVisibilityPercentage, 100);
    expect(restored.playerVisibilityPercentage, 95);
    expect(restored.shotChart, hasLength(1));
    expect(restored.shotChart.single.made, isTrue);
    expect(restored.shotChart.single.zone, CourtZone.leftWing);
  });

  test('loads older session records without a court zone', () {
    final restored = TrainingSession.fromJson({
      'id': 'legacy',
      'modeTitle': 'Live Shot Tracking',
      'startedAt': '2026-06-15T18:00:00.000Z',
      'endedAt': '2026-06-15T18:10:00.000Z',
      'makes': 6,
      'misses': 4,
      'durationSeconds': 600,
      'distanceMeters': null,
    });

    expect(restored.courtZone, isNull);
    expect(restored.makeFlightTimesMs, isEmpty);
    expect(restored.missFlightTimesMs, isEmpty);
    expect(restored.processedDetectionFrames, 0);
    expect(restored.averageInferenceTimeMs, isNull);
    expect(restored.shotChart, isEmpty);
  });
}
