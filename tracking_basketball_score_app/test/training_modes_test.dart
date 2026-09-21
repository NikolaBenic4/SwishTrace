import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_basketball_score_app/screens/home/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('clearly labels mode destinations', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('LIVE CAMERA'), findsOneWidget);
    expect(find.text('CAMERA + SETUP'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Friend Battle'), 300);
    expect(find.text('ONLINE'), findsOneWidget);
  });

  testWidgets('form session explains why it does not open the camera', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Form Session'));
    await tester.pumpAndSettle();

    expect(
      find.text('This mode needs hand and body keypoints.'),
      findsOneWidget,
    );
    expect(find.text('Open camera'), findsNothing);
  });

  testWidgets('friend battle opens the online experience', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeScreen())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Friend Battle'), 300);
    await tester.tap(find.text('Friend Battle'));
    await tester.pumpAndSettle();

    expect(find.text('ShotLab account'), findsOneWidget);
    expect(find.text('Open camera'), findsNothing);
  });
}
