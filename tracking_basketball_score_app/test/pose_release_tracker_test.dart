import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/services/pose_release_tracker.dart';

void main() {
  test('measures hand possession until the ball separates from the wrist', () {
    final tracker = PoseReleaseTracker();
    final started = DateTime.utc(2026, 6, 22, 12);

    expect(
      tracker.process(
        PoseReleaseFrame(
          capturedAt: started,
          ballCenter: const PosePoint(0.5, 0.5),
          rightWrist: const PosePoint(0.52, 0.52),
          leftWrist: null,
        ),
      ),
      isNull,
    );

    final release = tracker.process(
      PoseReleaseFrame(
        capturedAt: started.add(const Duration(milliseconds: 480)),
        ballCenter: const PosePoint(0.5, 0.2),
        rightWrist: const PosePoint(0.52, 0.52),
        leftWrist: null,
      ),
    );

    expect(release, const Duration(milliseconds: 480));
  });

  test('does not report release without observed possession', () {
    final tracker = PoseReleaseTracker();
    expect(
      tracker.process(
        PoseReleaseFrame(
          capturedAt: DateTime.utc(2026),
          ballCenter: const PosePoint(0.5, 0.1),
          rightWrist: const PosePoint(0.5, 0.8),
          leftWrist: null,
        ),
      ),
      isNull,
    );
  });
}
