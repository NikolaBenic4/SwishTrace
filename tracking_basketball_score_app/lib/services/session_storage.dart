import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_session.dart';

class SessionStorage {
  SessionStorage({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _sessionsKey = 'training_sessions_v1';
  static const _maximumStoredSessions = 100;

  final Future<SharedPreferences> _preferences;

  Future<List<TrainingSession>> loadSessions() async {
    final preferences = await _preferences;
    final encodedSessions = preferences.getStringList(_sessionsKey) ?? const [];
    final sessions = <TrainingSession>[];

    for (final encoded in encodedSessions) {
      try {
        final json = jsonDecode(encoded) as Map<String, Object?>;
        sessions.add(TrainingSession.fromJson(json));
      } on FormatException {
        // Ignore a damaged record while preserving the rest of the history.
      } on TypeError {
        // Ignore records from an incompatible schema.
      }
    }

    sessions.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return sessions;
  }

  Future<void> saveSession(TrainingSession session) async {
    final preferences = await _preferences;
    final sessions = await loadSessions();
    final updated = [
      session,
      ...sessions.where((stored) => stored.id != session.id),
    ].take(_maximumStoredSessions);

    await preferences.setStringList(
      _sessionsKey,
      updated.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
