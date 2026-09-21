import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/court_zone.dart';
import 'package:tracking_basketball_score_app/models/shot_chart_entry.dart';

void main() {
  test('maps half-court coordinates to shooting zones', () {
    expect(courtZoneForPosition(0.5, 0.2), CourtZone.paint);
    expect(courtZoneForPosition(0.1, 0.3), CourtZone.leftCorner);
    expect(courtZoneForPosition(0.9, 0.3), CourtZone.rightCorner);
    expect(courtZoneForPosition(0.5, 0.5), CourtZone.midRange);
    expect(courtZoneForPosition(0.2, 0.75), CourtZone.leftWing);
    expect(courtZoneForPosition(0.8, 0.75), CourtZone.rightWing);
    expect(courtZoneForPosition(0.5, 0.8), CourtZone.top);
  });

  test('serializes a made shot and its court position', () {
    final shot = ShotChartEntry(
      x: 0.25,
      y: 0.8,
      made: true,
      capturedAt: DateTime.utc(2026, 6, 22),
      trackedFlightTimeMs: 480,
    );

    final restored = ShotChartEntry.fromJson(shot.toJson());

    expect(restored.x, 0.25);
    expect(restored.y, 0.8);
    expect(restored.made, isTrue);
    expect(restored.trackedFlightTimeMs, 480);
  });
}
