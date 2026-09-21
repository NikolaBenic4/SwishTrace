import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/online_models.dart';

class AccountStorage {
  AccountStorage({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _key = 'shotlab_account_v1';
  final Future<SharedPreferences> _preferences;

  Future<ShotLabAccount?> load() async {
    final encoded = (await _preferences).getString(_key);
    if (encoded == null) return null;
    try {
      return ShotLabAccount.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(ShotLabAccount account) async {
    await (await _preferences).setString(_key, jsonEncode(account.toJson()));
  }

  Future<void> clear() async {
    await (await _preferences).remove(_key);
  }
}
