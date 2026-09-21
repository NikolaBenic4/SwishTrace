import 'court_zone.dart';
import 'zone_statistics.dart';

class WeakZoneDrillRecommendation {
  const WeakZoneDrillRecommendation({
    required this.zone,
    required this.title,
    required this.focus,
    required this.drill,
    required this.makes,
    required this.attempts,
    required this.percentage,
  });

  final CourtZone zone;
  final String title;
  final String focus;
  final String drill;
  final int makes;
  final int attempts;
  final int percentage;
}

WeakZoneDrillRecommendation? recommendWeakZoneDrill(
  Iterable<ZoneStatistics> statistics, {
  int minimumAttempts = 5,
}) {
  final eligibleZones =
      statistics.where((item) => item.attempts >= minimumAttempts).toList()
        ..sort((a, b) {
          final percentageComparison = a.percentage.compareTo(b.percentage);
          if (percentageComparison != 0) {
            return percentageComparison;
          }
          return b.attempts.compareTo(a.attempts);
        });

  if (eligibleZones.isEmpty) {
    return null;
  }

  final weakest = eligibleZones.first;
  final plan = _drillPlanFor(weakest.zone);

  return WeakZoneDrillRecommendation(
    zone: weakest.zone,
    title: plan.title,
    focus: plan.focus,
    drill: plan.drill,
    makes: weakest.makes,
    attempts: weakest.attempts,
    percentage: weakest.percentage,
  );
}

_DrillPlan _drillPlanFor(CourtZone zone) {
  return switch (zone) {
    CourtZone.leftCorner => const _DrillPlan(
      title: 'Corner base builder',
      focus: 'Square your feet early and hold the follow-through.',
      drill:
          'Take 5 sets of 5 from the left corner. Reset your feet after '
          'each shot and track makes by set.',
    ),
    CourtZone.rightCorner => const _DrillPlan(
      title: 'Corner base builder',
      focus: 'Square your feet early and hold the follow-through.',
      drill:
          'Take 5 sets of 5 from the right corner. Reset your feet after '
          'each shot and track makes by set.',
    ),
    CourtZone.leftWing => const _DrillPlan(
      title: 'Wing rhythm series',
      focus: 'Find the same dip and release point every rep.',
      drill:
          'Shoot 4 sets of 6 from the left wing: two catch-and-shoot, two '
          'one-dribble pull-up sets.',
    ),
    CourtZone.rightWing => const _DrillPlan(
      title: 'Wing rhythm series',
      focus: 'Find the same dip and release point every rep.',
      drill:
          'Shoot 4 sets of 6 from the right wing: two catch-and-shoot, two '
          'one-dribble pull-up sets.',
    ),
    CourtZone.top => const _DrillPlan(
      title: 'Top-of-key alignment',
      focus: 'Keep shoulders straight to the rim through the release.',
      drill:
          'Shoot 25 top-of-key reps in groups of 5. Pause after misses and '
          'check shoulder alignment before the next shot.',
    ),
    CourtZone.midRange => const _DrillPlan(
      title: 'Mid-range touch ladder',
      focus: 'Use soft arc and consistent landing balance.',
      drill:
          'Shoot 3 rounds of 8 mid-range shots, moving one step left or '
          'right after every make.',
    ),
    CourtZone.paint => const _DrillPlan(
      title: 'Paint finish reset',
      focus: 'Finish high off two feet and keep eyes on the target.',
      drill:
          'Take 20 paint finishes, alternating sides. Count only clean '
          'makes without fading away.',
    ),
  };
}

class _DrillPlan {
  const _DrillPlan({
    required this.title,
    required this.focus,
    required this.drill,
  });

  final String title;
  final String focus;
  final String drill;
}
