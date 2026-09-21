import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_basketball_score_app/models/shot_chart_entry.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';
import 'package:tracking_basketball_score_app/screens/home/home_screen.dart';
import 'package:tracking_basketball_score_app/screens/profile/profile_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('profile button opens statistics and achievements dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Overall statistics'), findsOneWidget);
    expect(find.text('Personal records'), findsOneWidget);
    expect(find.text('Lifetime shot chart'), findsOneWidget);
    expect(find.textContaining('Achievements ('), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
  });

  testWidgets('recent activity opens the selected session review', (
    tester,
  ) async {
    final session = TrainingSession(
      id: 'profile-review',
      modeTitle: 'Live Shot Tracking',
      startedAt: DateTime.utc(2026, 6, 22, 18),
      endedAt: DateTime.utc(2026, 6, 22, 18, 10),
      makes: 1,
      misses: 1,
      durationSeconds: 600,
      shotChart: [
        ShotChartEntry(
          x: 0.25,
          y: 0.75,
          made: true,
          capturedAt: DateTime.utc(2026, 6, 22, 18, 2),
        ),
        ShotChartEntry(
          x: 0.75,
          y: 0.75,
          made: false,
          capturedAt: DateTime.utc(2026, 6, 22, 18, 3),
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'training_sessions_v1': [jsonEncode(session.toJson())],
    });
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/2 • 50%'));
    await tester.pumpAndSettle();

    expect(find.text('Session review'), findsOneWidget);
    expect(find.text('2 of 2 shots shown'), findsOneWidget);
  });

  testWidgets(
    'statistics and coverage tiles do not overflow on narrow screens',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final list = find.byType(ListView).first;
      await tester.drag(list, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
