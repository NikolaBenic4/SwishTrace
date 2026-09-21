import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/training_mode.dart';

void main() {
  test('only Distance Challenge requires a court spot', () {
    final freeShooting = TrainingMode(
      title: 'Live Shot Tracking',
      subtitle: '',
      icon: Icons.videocam,
      accent: Colors.orange,
      metrics: '',
      badge: 'LIVE CAMERA',
      destination: TrainingModeDestination.liveCamera,
      instructions: const [],
    );
    final distanceChallenge = TrainingMode(
      title: 'Distance Challenge',
      subtitle: '',
      icon: Icons.radar,
      accent: Colors.blue,
      metrics: '',
      badge: 'CAMERA + SETUP',
      destination: TrainingModeDestination.distanceCamera,
      instructions: const [],
    );

    expect(freeShooting.requiresCourtSpot, isFalse);
    expect(distanceChallenge.requiresCourtSpot, isTrue);
    expect(freeShooting.usesPortraitSetup, isFalse);
    expect(distanceChallenge.usesPortraitSetup, isTrue);
  });
}
