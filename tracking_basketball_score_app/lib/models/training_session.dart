import 'court_zone.dart';
import 'shot_chart_entry.dart';

class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.modeTitle,
    required this.startedAt,
    required this.endedAt,
    required this.makes,
    required this.misses,
    required this.durationSeconds,
    this.distanceMeters,
    this.courtZone,
    this.makeFlightTimesMs = const [],
    this.missFlightTimesMs = const [],
    this.processedDetectionFrames = 0,
    this.totalInferenceTimeMs = 0,
    this.ballVisibleFrames = 0,
    this.rimVisibleFrames = 0,
    this.playerVisibleFrames = 0,
    this.shotChart = const [],
  });

  factory TrainingSession.fromJson(Map<String, Object?> json) {
    return TrainingSession(
      id: json['id']! as String,
      modeTitle: json['modeTitle']! as String,
      startedAt: DateTime.parse(json['startedAt']! as String),
      endedAt: DateTime.parse(json['endedAt']! as String),
      makes: json['makes']! as int,
      misses: json['misses']! as int,
      durationSeconds: json['durationSeconds']! as int,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      courtZone: CourtZone.fromName(json['courtZone'] as String?),
      makeFlightTimesMs: _intList(json['makeFlightTimesMs']),
      missFlightTimesMs: _intList(json['missFlightTimesMs']),
      processedDetectionFrames:
          (json['processedDetectionFrames'] as num?)?.toInt() ?? 0,
      totalInferenceTimeMs:
          (json['totalInferenceTimeMs'] as num?)?.toInt() ?? 0,
      ballVisibleFrames: (json['ballVisibleFrames'] as num?)?.toInt() ?? 0,
      rimVisibleFrames: (json['rimVisibleFrames'] as num?)?.toInt() ?? 0,
      playerVisibleFrames: (json['playerVisibleFrames'] as num?)?.toInt() ?? 0,
      shotChart: _shotChart(json['shotChart']),
    );
  }

  final String id;
  final String modeTitle;
  final DateTime startedAt;
  final DateTime endedAt;
  final int makes;
  final int misses;
  final int durationSeconds;
  final double? distanceMeters;
  final CourtZone? courtZone;
  final List<int> makeFlightTimesMs;
  final List<int> missFlightTimesMs;
  final int processedDetectionFrames;
  final int totalInferenceTimeMs;
  final int ballVisibleFrames;
  final int rimVisibleFrames;
  final int playerVisibleFrames;
  final List<ShotChartEntry> shotChart;

  int get attempts => makes + misses;
  int get percentage => attempts == 0 ? 0 : (makes / attempts * 100).round();
  int? get averageInferenceTimeMs => processedDetectionFrames == 0
      ? null
      : (totalInferenceTimeMs / processedDetectionFrames).round();

  int visibilityPercentage(int visibleFrames) => processedDetectionFrames == 0
      ? 0
      : (visibleFrames / processedDetectionFrames * 100).round();

  int get ballVisibilityPercentage => visibilityPercentage(ballVisibleFrames);
  int get rimVisibilityPercentage => visibilityPercentage(rimVisibleFrames);
  int get playerVisibilityPercentage =>
      visibilityPercentage(playerVisibleFrames);

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'modeTitle': modeTitle,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'makes': makes,
      'misses': misses,
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'courtZone': courtZone?.name,
      'makeFlightTimesMs': makeFlightTimesMs,
      'missFlightTimesMs': missFlightTimesMs,
      'processedDetectionFrames': processedDetectionFrames,
      'totalInferenceTimeMs': totalInferenceTimeMs,
      'ballVisibleFrames': ballVisibleFrames,
      'rimVisibleFrames': rimVisibleFrames,
      'playerVisibleFrames': playerVisibleFrames,
      'shotChart': shotChart.map((entry) => entry.toJson()).toList(),
    };
  }

  static List<int> _intList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<num>().map((item) => item.toInt()).toList();
  }

  static List<ShotChartEntry> _shotChart(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map(
          (item) => ShotChartEntry.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
}
