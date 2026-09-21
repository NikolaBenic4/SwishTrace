import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/services/shot_detector_service.dart';
import 'package:tracking_basketball_score_app/services/shot_event_tracker.dart';

void main() {
  final start = DateTime(2026, 6, 15, 18);

  test('detects a make when the ball crosses down through the rim', () {
    final tracker = ShotEventTracker();

    expect(tracker.process(_frame(ballX: 0.5, ballY: 0.2), start), isNull);
    expect(
      tracker.process(
        _frame(ballX: 0.5, ballY: 0.29),
        start.add(const Duration(milliseconds: 300)),
      ),
      isNull,
    );

    final event = tracker.process(
      _frame(ballX: 0.5, ballY: 0.38),
      start.add(const Duration(milliseconds: 600)),
    );

    expect(event?.result, ShotResult.make);
    expect(event?.confidence, closeTo(0.9, 0.001));
    expect(event?.trackedFlightTime, const Duration(milliseconds: 600));
  });

  test('detects a miss after a valid approach passes outside the rim', () {
    final tracker = ShotEventTracker();

    expect(tracker.process(_frame(ballX: 0.58, ballY: 0.2), start), isNull);
    expect(
      tracker.process(
        _frame(ballX: 0.63, ballY: 0.3),
        start.add(const Duration(milliseconds: 300)),
      ),
      isNull,
    );

    final event = tracker.process(
      _frame(ballX: 0.7, ballY: 0.43),
      start.add(const Duration(milliseconds: 600)),
    );

    expect(event?.result, ShotResult.miss);
    expect(event?.trackedFlightTime, const Duration(milliseconds: 600));
  });

  test(
    'ignores a ball moving below the rim without an approach from above',
    () {
      final tracker = ShotEventTracker();

      expect(tracker.process(_frame(ballX: 0.5, ballY: 0.4), start), isNull);
      expect(
        tracker.process(
          _frame(ballX: 0.5, ballY: 0.5),
          start.add(const Duration(milliseconds: 300)),
        ),
        isNull,
      );
    },
  );

  test('cooldown prevents a single trajectory from counting twice', () {
    final tracker = ShotEventTracker();
    tracker.process(_frame(ballX: 0.5, ballY: 0.2), start);
    final event = tracker.process(
      _frame(ballX: 0.5, ballY: 0.4),
      start.add(const Duration(milliseconds: 300)),
    );
    expect(event?.result, ShotResult.make);

    expect(
      tracker.process(
        _frame(ballX: 0.5, ballY: 0.2),
        start.add(const Duration(milliseconds: 600)),
      ),
      isNull,
    );
  });

  test('bridges a short rim detection dropout', () {
    final tracker = ShotEventTracker();

    expect(tracker.process(_frame(ballX: 0.5, ballY: 0.2), start), isNull);
    expect(
      tracker.process([
        _ball(ballX: 0.5, ballY: 0.29),
      ], start.add(const Duration(milliseconds: 300))),
      isNull,
    );

    final event = tracker.process(
      _frame(ballX: 0.5, ballY: 0.38),
      start.add(const Duration(milliseconds: 600)),
    );

    expect(event?.result, ShotResult.make);
  });
}

List<YoloDetection> _frame({required double ballX, required double ballY}) {
  return [_ball(ballX: ballX, ballY: ballY), _rim()];
}

YoloDetection _ball({required double ballX, required double ballY}) {
  return YoloDetection(
    left: ballX - 0.02,
    top: ballY - 0.02,
    width: 0.04,
    height: 0.04,
    confidence: 0.9,
    label: 'ball',
    isBall: true,
  );
}

YoloDetection _rim() {
  return YoloDetection(
    left: 0.4,
    top: 0.3,
    width: 0.2,
    height: 0.05,
    confidence: 0.9,
    label: 'rim',
  );
}
