import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/models/shot_chart_entry.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';
import 'package:tracking_basketball_score_app/screens/session_detail/session_detail_screen.dart';
import 'package:tracking_basketball_score_app/widgets/half_court_shot_chart.dart';

void main() {
  testWidgets('filters a reviewed session by all shots, makes, and misses', (
    tester,
  ) async {
    final session = TrainingSession(
      id: 'review',
      modeTitle: 'Live Shot Tracking',
      startedAt: DateTime.utc(2026, 6, 22, 18),
      endedAt: DateTime.utc(2026, 6, 22, 18, 10),
      makes: 2,
      misses: 1,
      durationSeconds: 600,
      shotChart: [_shot(0.2, true), _shot(0.5, false), _shot(0.8, true)],
    );

    await tester.pumpWidget(
      MaterialApp(home: SessionDetailScreen(session: session)),
    );

    expect(find.text('3 of 3 shots shown'), findsOneWidget);
    expect(_chart(tester).shots, hasLength(3));

    await tester.tap(find.text('Makes'));
    await tester.pump();
    expect(find.text('2 of 3 shots shown'), findsOneWidget);
    expect(_chart(tester).shots, hasLength(2));
    expect(_chart(tester).shots.every((shot) => shot.made), isTrue);

    await tester.tap(find.text('Misses'));
    await tester.pump();
    expect(find.text('1 of 3 shots shown'), findsOneWidget);
    expect(_chart(tester).shots, hasLength(1));
    expect(_chart(tester).shots.single.made, isFalse);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(_chart(tester).shots, hasLength(3));
  });
}

HalfCourtShotChart _chart(WidgetTester tester) {
  return tester.widget<HalfCourtShotChart>(
    find.byType(HalfCourtShotChart).first,
  );
}

ShotChartEntry _shot(double x, bool made) {
  return ShotChartEntry(
    x: x,
    y: 0.75,
    made: made,
    capturedAt: DateTime.utc(2026, 6, 22),
  );
}
