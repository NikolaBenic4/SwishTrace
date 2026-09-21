import 'court_zone.dart';

class ShotChartEntry {
  const ShotChartEntry({
    required this.x,
    required this.y,
    required this.made,
    required this.capturedAt,
    this.trackedFlightTimeMs,
  });

  factory ShotChartEntry.fromJson(Map<String, Object?> json) {
    return ShotChartEntry(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      made: json['made']! as bool,
      capturedAt: DateTime.parse(json['capturedAt']! as String),
      trackedFlightTimeMs: (json['trackedFlightTimeMs'] as num?)?.toInt(),
    );
  }

  final double x;
  final double y;
  final bool made;
  final DateTime capturedAt;
  final int? trackedFlightTimeMs;

  CourtZone get zone => courtZoneForPosition(x, y);

  Map<String, Object?> toJson() => {
    'x': x,
    'y': y,
    'made': made,
    'capturedAt': capturedAt.toIso8601String(),
    'trackedFlightTimeMs': trackedFlightTimeMs,
  };
}

CourtZone courtZoneForPosition(double x, double y) {
  if (y <= 0.3 && x >= 0.34 && x <= 0.66) {
    return CourtZone.paint;
  }
  if (y <= 0.42 && x < 0.22) {
    return CourtZone.leftCorner;
  }
  if (y <= 0.42 && x > 0.78) {
    return CourtZone.rightCorner;
  }
  if (y <= 0.58) {
    return CourtZone.midRange;
  }
  if (x < 0.4) {
    return CourtZone.leftWing;
  }
  if (x > 0.6) {
    return CourtZone.rightWing;
  }
  return CourtZone.top;
}
