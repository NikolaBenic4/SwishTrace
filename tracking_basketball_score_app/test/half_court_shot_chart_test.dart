import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/widgets/half_court_shot_chart.dart';

void main() {
  testWidgets('spot picker returns a tapped normalized court position', (
    tester,
  ) async {
    Offset? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  selected = await showDialog<Offset>(
                    context: context,
                    builder: (_) => const ShootingSpotPicker(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final chart = find.byType(HalfCourtShotChart);
    final rect = tester.getRect(chart);
    await tester.tapAt(
      Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.75),
    );
    await tester.pump();
    await tester.tap(find.text('Use this spot'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.dx, closeTo(0.25, 0.03));
    expect(selected!.dy, closeTo(0.75, 0.03));
  });

  testWidgets('landscape spot picker keeps the complete court aspect ratio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ShootingSpotPicker(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(HalfCourtShotChart));
    expect(size.width / size.height, closeTo(50 / 47, 0.01));
    expect(size.height, greaterThan(250));
  });

  testWidgets('portrait spot picker uses a compact court preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ShootingSpotPicker(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(HalfCourtShotChart));
    expect(size.width / size.height, closeTo(50 / 47, 0.01));
    expect(size.height, lessThanOrEqualTo(180));
    expect(find.text('Use this spot'), findsOneWidget);
  });
}
