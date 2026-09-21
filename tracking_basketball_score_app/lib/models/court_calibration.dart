enum CourtDistancePreset {
  freeThrow('Free throw', 4.57),
  fibaThreePoint('FIBA three-point', 6.75),
  nbaThreePoint('NBA three-point', 7.24);

  const CourtDistancePreset(this.label, this.distanceMeters);

  final String label;
  final double distanceMeters;
}

class CourtCalibration {
  const CourtCalibration({required this.distanceMeters, required this.label});

  factory CourtCalibration.fromPreset(CourtDistancePreset preset) {
    return CourtCalibration(
      distanceMeters: preset.distanceMeters,
      label: preset.label,
    );
  }

  factory CourtCalibration.custom(double distanceMeters) {
    if (distanceMeters < 1 || distanceMeters > 15) {
      throw ArgumentError.value(
        distanceMeters,
        'distanceMeters',
        'Distance must be between 1 and 15 meters.',
      );
    }

    return CourtCalibration(distanceMeters: distanceMeters, label: 'Custom');
  }

  final double distanceMeters;
  final String label;

  String get displayDistance => '${distanceMeters.toStringAsFixed(2)} m';
}
