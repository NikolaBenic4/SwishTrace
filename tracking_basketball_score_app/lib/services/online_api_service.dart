import 'dart:convert';
import 'dart:io';

import '../models/online_models.dart';
import '../models/training_session.dart';

class OnlineConfiguration {
  const OnlineConfiguration({
    this.firebaseApiKey = const String.fromEnvironment('FIREBASE_API_KEY'),
    this.apiBaseUrl = const String.fromEnvironment('SHOTLAB_API_BASE_URL'),
  });

  final String firebaseApiKey;
  final String apiBaseUrl;

  bool get canAuthenticate => firebaseApiKey.isNotEmpty;
  bool get canSync => apiBaseUrl.isNotEmpty;
}

class OnlineApiException implements Exception {
  const OnlineApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class OnlineApiService {
  OnlineApiService({
    this.configuration = const OnlineConfiguration(),
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  final OnlineConfiguration configuration;
  final HttpClient _client;

  Future<ShotLabAccount> signUp(String email, String password) {
    return _authenticate('signUp', email, password);
  }

  Future<ShotLabAccount> signIn(String email, String password) {
    return _authenticate('signInWithPassword', email, password);
  }

  Future<void> saveSession(
    ShotLabAccount account,
    TrainingSession session,
  ) async {
    await _apiRequest('POST', '/sessions', account.idToken, session.toJson());
  }

  Future<void> saveShotEvent(
    ShotLabAccount account, {
    required String sessionId,
    required String shotId,
    required String result,
    required int trackedFlightTimeMs,
    double? distanceMeters,
    String? courtZone,
    double? courtX,
    double? courtY,
  }) async {
    await _apiRequest('POST', '/shots', account.idToken, {
      'sessionId': sessionId,
      'shotId': shotId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'result': result,
      'trackedFlightTimeMs': trackedFlightTimeMs,
      'distanceMeters': distanceMeters,
      'courtZone': courtZone,
      'courtX': courtX,
      'courtY': courtY,
    });
  }

  Future<List<FriendProfile>> loadFriends(ShotLabAccount account) async {
    final response = await _apiRequest('GET', '/friends', account.idToken);
    return (response['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => FriendProfile.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<void> addFriend(ShotLabAccount account, String friendEmail) async {
    await _apiRequest('POST', '/friends', account.idToken, {
      'email': friendEmail,
    });
  }

  Future<List<LeaderboardEntry>> loadLeaderboard(ShotLabAccount account) async {
    final response = await _apiRequest('GET', '/leaderboard', account.idToken);
    return (response['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => LeaderboardEntry.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<void> createChallenge(
    ShotLabAccount account, {
    required String friendUserId,
    required int targetMakes,
  }) async {
    await _apiRequest('POST', '/challenges', account.idToken, {
      'friendUserId': friendUserId,
      'targetMakes': targetMakes,
    });
  }

  Future<ShotLabAccount> _authenticate(
    String method,
    String email,
    String password,
  ) async {
    if (!configuration.canAuthenticate) {
      throw const OnlineApiException(
        'Set FIREBASE_API_KEY with --dart-define to enable accounts.',
      );
    }
    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:$method',
      {'key': configuration.firebaseApiKey},
    );
    final response = await _jsonRequest(
      'POST',
      uri,
      body: {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      },
    );
    return ShotLabAccount(
      userId: response['localId']! as String,
      email: response['email']! as String,
      idToken: response['idToken']! as String,
      refreshToken: response['refreshToken']! as String,
    );
  }

  Future<Map<String, Object?>> _apiRequest(
    String method,
    String path,
    String token, [
    Map<String, Object?>? body,
  ]) {
    if (!configuration.canSync) {
      throw const OnlineApiException(
        'Set SHOTLAB_API_BASE_URL with --dart-define to enable cloud sync.',
      );
    }
    return _jsonRequest(
      method,
      Uri.parse('${configuration.apiBaseUrl}$path'),
      token: token,
      body: body,
    );
  }

  Future<Map<String, Object?>> _jsonRequest(
    String method,
    Uri uri, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final request = await _client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) request.write(jsonEncode(body));
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    final decoded = text.isEmpty
        ? <String, Object?>{}
        : jsonDecode(text) as Map<String, Object?>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final message = error is Map
          ? error['message']?.toString()
          : decoded['message']?.toString();
      throw OnlineApiException(message ?? 'Online request failed.');
    }
    return decoded;
  }
}
