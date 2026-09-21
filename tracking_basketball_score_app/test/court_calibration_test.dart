import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/court_calibration.dart';

void main() {
  test('creates calibration from a marked court preset', () {
    final calibration = CourtCalibration.fromPreset(
      CourtDistancePreset.freeThrow,
    );

    expect(calibration.distanceMeters, 4.57);
    expect(calibration.displayDistance, '4.57 m');
    expect(calibration.label, 'Free throw');
  });

  test('accepts custom court distances within the supported range', () {
    final calibration = CourtCalibration.custom(5.5);

    expect(calibration.displayDistance, '5.50 m');
    expect(calibration.label, 'Custom');
  });

  test('rejects invalid custom court distances', () {
    expect(() => CourtCalibration.custom(0.5), throwsArgumentError);
    expect(() => CourtCalibration.custom(16), throwsArgumentError);
  });
}
