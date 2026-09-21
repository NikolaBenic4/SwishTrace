import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/screens/build_board/build_board_screen.dart';

void main() {
  testWidgets('shows current roadmap focus and blocker', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BuildBoardScreen())),
    );

    expect(find.text('Current Focus'), findsOneWidget);
    expect(find.text('20-shot court validation'), findsOneWidget);
    expect(find.text('Threshold tuning'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });
}
