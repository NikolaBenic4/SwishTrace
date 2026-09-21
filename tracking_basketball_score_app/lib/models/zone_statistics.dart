import 'court_zone.dart';
import 'training_session.dart';

class ZoneStatistics {
  const ZoneStatistics({
    required this.zone,
    required this.makes,
    required this.attempts,
  });

  final CourtZone zone;
  final int makes;
  final int attempts;

  int get percentage => attempts == 0 ? 0 : (makes / attempts * 100).round();
}

List<ZoneStatistics> calculateZoneStatistics(
  Iterable<TrainingSession> sessions,
) {
  final makes = {for (final zone in CourtZone.values) zone: 0};
  final attempts = {for (final zone in CourtZone.values) zone: 0};

  for (final session in sessions) {
    if (session.shotChart.isNotEmpty) {
      for (final shot in session.shotChart) {
        final zone = shot.zone;
        attempts[zone] = attempts[zone]! + 1;
        if (shot.made) {
          makes[zone] = makes[zone]! + 1;
        }
      }
      continue;
    }
    final zone = session.courtZone;
    if (zone == null) {
      continue;
    }
    makes[zone] = makes[zone]! + session.makes;
    attempts[zone] = attempts[zone]! + session.attempts;
  }

  return [
    for (final zone in CourtZone.values)
      ZoneStatistics(
        zone: zone,
        makes: makes[zone]!,
        attempts: attempts[zone]!,
      ),
  ];
}
