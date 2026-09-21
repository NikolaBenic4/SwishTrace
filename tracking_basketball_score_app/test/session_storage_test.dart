import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_basketball_score_app/models/training_session.dart';
import 'package:tracking_basketball_score_app/services/session_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and loads sessions newest first', () async {
    final storage = SessionStorage();
    final older = _session('older', DateTime.utc(2026, 6, 14));
    final newer = _session('newer', DateTime.utc(2026, 6, 15));

    await storage.saveSession(older);
    await storage.saveSession(newer);

    final sessions = await storage.loadSessions();

    expect(sessions.map((session) => session.id), ['newer', 'older']);
  });

  test('preserves a zero-attempt session and its detection diagnostics',
      () async {
    final storage = SessionStorage();
    final session = TrainingSession(
      id: 'diagnostic-session',
      modeTitle: 'Live Shot Tracking',
      startedAt: DateTime.utc(2026, 9, 16, 16),
      endedAt: DateTime.utc(2026, 9, 16, 16, 5),
      makes: 0,
      misses: 0,
      durationSeconds: 300,
      processedDetectionFrames: 120,
      ballVisibleFrames: 42,
      rimVisibleFrames: 108,
    );

    await storage.saveSession(session);
    final restored = (await storage.loadSessions()).single;

    expect(restored.attempts, 0);
    expect(restored.durationSeconds, 300);
    expect(restored.processedDetectionFrames, 120);
    expect(restored.ballVisibleFrames, 42);
    expect(restored.rimVisibleFrames, 108);
  });
}

TrainingSession _session(String id, DateTime endedAt) {
  return TrainingSession(
    id: id,
    modeTitle: 'Live Shot Tracking',
    startedAt: endedAt.subtract(const Duration(minutes: 5)),
    endedAt: endedAt,
    makes: 4,
    misses: 2,
    durationSeconds: 300,
  );
}
