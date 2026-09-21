import 'package:flutter/material.dart';

enum TrainingModeDestination {
  liveCamera,
  distanceCamera,
  online,
  levels,
  unavailable,
}

class TrainingMode {
  const TrainingMode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.metrics,
    required this.badge,
    required this.destination,
    required this.instructions,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String metrics;
  final String badge;
  final TrainingModeDestination destination;
  final List<String> instructions;

  bool get usesCamera =>
      destination == TrainingModeDestination.liveCamera ||
      destination == TrainingModeDestination.distanceCamera;

  bool get requiresCourtSpot =>
      destination == TrainingModeDestination.distanceCamera;

  bool get usesPortraitSetup =>
      destination == TrainingModeDestination.distanceCamera;
}
