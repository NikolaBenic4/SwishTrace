import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/court_zone.dart';
import 'package:tracking_basketball_score_app/models/weak_zone_drill_recommendation.dart';
import 'package:tracking_basketball_score_app/models/zone_statistics.dart';

void main() {
  test(
    'recommends a drill for the eligible zone with the lowest percentage',
    () {
      final recommendation = recommendWeakZoneDrill([
        const ZoneStatistics(zone: CourtZone.leftWing, makes: 6, attempts: 10),
        const ZoneStatistics(
          zone: CourtZone.rightCorner,
          makes: 2,
          attempts: 8,
        ),
        const ZoneStatistics(zone: CourtZone.paint, makes: 4, attempts: 4),
      ]);

      expect(recommendation, isNotNull);
      expect(recommendation!.zone, CourtZone.rightCorner);
      expect(recommendation.percentage, 25);
      expect(recommendation.title, 'Corner base builder');
    },
  );

  test('uses more attempts as the tie-breaker for matching percentages', () {
    final recommendation = recommendWeakZoneDrill([
      const ZoneStatistics(zone: CourtZone.leftWing, makes: 3, attempts: 6),
      const ZoneStatistics(zone: CourtZone.top, makes: 5, attempts: 10),
    ]);

    expect(recommendation, isNotNull);
    expect(recommendation!.zone, CourtZone.top);
  });

  test('does not recommend a weak zone until enough shots are tracked', () {
    final recommendation = recommendWeakZoneDrill([
      const ZoneStatistics(zone: CourtZone.leftWing, makes: 0, attempts: 4),
      const ZoneStatistics(zone: CourtZone.top, makes: 1, attempts: 3),
    ]);

    expect(recommendation, isNull);
  });
}
