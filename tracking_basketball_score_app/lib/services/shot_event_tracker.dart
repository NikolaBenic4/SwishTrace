import 'dart:math' as math;

import 'shot_detector_service.dart';

enum ShotResult { make, miss }

class ShotEvent {
  const ShotEvent({
    required this.result,
    required this.timestamp,
    required this.confidence,
    required this.trackedFlightTime,
  });

  final ShotResult result;
  final DateTime timestamp;
  final double confidence;
  final Duration trackedFlightTime;
}

class ShotEventTracker {
  ShotEventTracker({
    this.maximumShotDuration = const Duration(seconds: 3),
    this.cooldown = const Duration(milliseconds: 1200),
    this.maximumDetectionGap = const Duration(milliseconds: 300),
  });

  final Duration maximumShotDuration;
  final Duration cooldown;
  final Duration maximumDetectionGap;

  _ShotCandidate? _candidate;
  DateTime? _cooldownUntil;
  YoloDetection? _lastRim;
  DateTime? _lastRimAt;

  ShotEvent? process(Iterable<YoloDetection> detections, DateTime timestamp) {
    final cooldownUntil = _cooldownUntil;
    if (cooldownUntil != null && timestamp.isBefore(cooldownUntil)) {
      return null;
    }

    final ball = _bestDetection(detections, 'ball');
    final detectedRim = _bestDetection(detections, 'rim');
    if (detectedRim != null) {
      _lastRim = detectedRim;
      _lastRimAt = timestamp;
    }
    final rim = detectedRim ?? _recentRim(timestamp);
    final candidate = _candidate;

    if (candidate != null &&
        timestamp.difference(candidate.startedAt) > maximumShotDuration) {
      _candidate = null;
    }

    if (ball == null || rim == null) {
      return null;
    }

    final ballCenter = _center(ball);
    final rimCenter = _center(rim);
    final rimWidth = math.max(rim.width, 0.01);
    final rimHeight = math.max(rim.height, 0.01);
    final horizontalDistance = (ballCenter.$1 - rimCenter.$1).abs();
    final isAboveRim = ballCenter.$2 < rim.top;
    final isNearRim = horizontalDistance <= rimWidth * 2.5;

    if (_candidate == null) {
      if (isAboveRim && isNearRim) {
        _candidate = _ShotCandidate(
          startedAt: timestamp,
          lastBallCenter: ballCenter,
          rim: rim,
          minimumBallY: ballCenter.$2,
          closestHorizontalDistance: horizontalDistance,
        );
      }
      return null;
    }

    final activeCandidate = _candidate!;
    activeCandidate
      ..rim = rim
      ..minimumBallY = math.min(activeCandidate.minimumBallY, ballCenter.$2)
      ..closestHorizontalDistance = math.min(
        activeCandidate.closestHorizontalDistance,
        horizontalDistance,
      );

    final previousCenter = activeCandidate.lastBallCenter;
    final isMovingDown = ballCenter.$2 > previousCenter.$2;
    final approachedFromAbove =
        activeCandidate.minimumBallY <= rim.top - rimHeight * 0.25;
    final crossedBelowRim =
        previousCenter.$2 <= rim.bottom && ballCenter.$2 > rim.bottom;
    final insideRimMouth =
        ballCenter.$1 >= rim.left - rimWidth * 0.2 &&
        ballCenter.$1 <= rim.right + rimWidth * 0.2;

    activeCandidate.lastBallCenter = ballCenter;

    if (approachedFromAbove &&
        isMovingDown &&
        crossedBelowRim &&
        insideRimMouth) {
      return _complete(
        ShotResult.make,
        timestamp,
        _eventConfidence(ball, rim),
        timestamp.difference(activeCandidate.startedAt),
      );
    }

    final clearlyBelowRim = ballCenter.$2 > rim.bottom + rimHeight * 1.5;
    final passedOutsideMouth =
        ballCenter.$1 < rim.left - rimWidth * 0.35 ||
        ballCenter.$1 > rim.right + rimWidth * 0.35;
    final hadValidApproach =
        activeCandidate.closestHorizontalDistance <= rimWidth * 2.0;

    if (approachedFromAbove &&
        isMovingDown &&
        clearlyBelowRim &&
        passedOutsideMouth &&
        hadValidApproach) {
      return _complete(
        ShotResult.miss,
        timestamp,
        _eventConfidence(ball, rim),
        timestamp.difference(activeCandidate.startedAt),
      );
    }

    return null;
  }

  void reset() {
    _candidate = null;
    _cooldownUntil = null;
    _lastRim = null;
    _lastRimAt = null;
  }

  YoloDetection? _recentRim(DateTime timestamp) {
    final rim = _lastRim;
    final rimAt = _lastRimAt;
    if (rim == null ||
        rimAt == null ||
        timestamp.difference(rimAt) > maximumDetectionGap) {
      return null;
    }
    return rim;
  }

  ShotEvent _complete(
    ShotResult result,
    DateTime timestamp,
    double confidence,
    Duration trackedFlightTime,
  ) {
    _candidate = null;
    _cooldownUntil = timestamp.add(cooldown);
    return ShotEvent(
      result: result,
      timestamp: timestamp,
      confidence: confidence,
      trackedFlightTime: trackedFlightTime,
    );
  }

  YoloDetection? _bestDetection(
    Iterable<YoloDetection> detections,
    String label,
  ) {
    YoloDetection? best;
    for (final detection in detections) {
      if (detection.label == label &&
          (best == null || detection.confidence > best.confidence)) {
        best = detection;
      }
    }
    return best;
  }

  (double, double) _center(YoloDetection detection) {
    return (
      detection.left + detection.width / 2,
      detection.top + detection.height / 2,
    );
  }

  double _eventConfidence(YoloDetection ball, YoloDetection rim) {
    return ((ball.confidence + rim.confidence) / 2).clamp(0, 1);
  }
}

class _ShotCandidate {
  _ShotCandidate({
    required this.startedAt,
    required this.lastBallCenter,
    required this.rim,
    required this.minimumBallY,
    required this.closestHorizontalDistance,
  });

  final DateTime startedAt;
  (double, double) lastBallCenter;
  YoloDetection rim;
  double minimumBallY;
  double closestHorizontalDistance;
}
