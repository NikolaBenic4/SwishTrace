import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/level_progress.dart';

class LevelProgressStorage {
  LevelProgressStorage({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _progressKey = 'training_level_progress_v1';

  final Future<SharedPreferences> _preferences;

  Future<LevelProgress> loadProgress() async {
    final preferences = await _preferences;
    final encoded = preferences.getString(_progressKey);
    if (encoded == null) return LevelProgress.initial();

    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      return LevelProgress.fromJson(json);
    } on FormatException {
      return LevelProgress.initial();
    } on TypeError {
      return LevelProgress.initial();
    }
  }

  Future<void> saveProgress(LevelProgress progress) async {
    final preferences = await _preferences;
    await preferences.setString(_progressKey, jsonEncode(progress.toJson()));
  }
}
