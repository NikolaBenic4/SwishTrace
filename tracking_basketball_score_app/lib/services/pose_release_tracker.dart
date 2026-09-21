import 'dart:math' as math;

class PosePoint {
  const PosePoint(this.x, this.y, {this.confidence = 1});

  final double x;
  final double y;
  final double confidence;

  double distanceTo(PosePoint other) {
    return math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
  }
}

class PoseReleaseFrame {
  const PoseReleaseFrame({
    required this.capturedAt,
    required this.ballCenter,
    required this.leftWrist,
    required this.rightWrist,
  });

  final DateTime capturedAt;
  final PosePoint? ballCenter;
  final PosePoint? leftWrist;
  final PosePoint? rightWrist;
}

class PoseReleaseTracker {
  PoseReleaseTracker({
    this.possessionDistance = 0.12,
    this.releaseDistance = 0.2,
    this.minimumConfidence = 0.45,
  });

  final double possessionDistance;
  final double releaseDistance;
  final double minimumConfidence;
  DateTime? _possessionStartedAt;
  bool _hadPossession = false;

  Duration? process(PoseReleaseFrame frame) {
    final ball = frame.ballCenter;
    if (ball == null || ball.confidence < minimumConfidence) return null;
    final wristDistance = [frame.leftWrist, frame.rightWrist]
        .whereType<PosePoint>()
        .where((point) => point.confidence >= minimumConfidence)
        .map(ball.distanceTo)
        .fold<double?>(null, (best, value) {
          return best == null || value < best ? value : best;
        });
    if (wristDistance == null) return null;

    if (wristDistance <= possessionDistance) {
      _possessionStartedAt ??= frame.capturedAt;
      _hadPossession = true;
      return null;
    }
    if (_hadPossession && wristDistance >= releaseDistance) {
      final startedAt = _possessionStartedAt;
      reset();
      return startedAt == null ? null : frame.capturedAt.difference(startedAt);
    }
    return null;
  }

  void reset() {
    _possessionStartedAt = null;
    _hadPossession = false;
  }
}
