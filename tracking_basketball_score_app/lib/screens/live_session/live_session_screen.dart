import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/court_calibration.dart';
import '../../models/court_zone.dart';
import '../../models/training_mode.dart';
import '../../models/training_session.dart';
import '../../models/online_models.dart';
import '../../models/shot_chart_entry.dart';
import '../../services/account_storage.dart';
import '../../services/online_api_service.dart';
import '../../services/session_storage.dart';
import '../../services/shot_detector_service.dart';
import '../../services/shot_event_tracker.dart';
import 'widgets/detection_overlay.dart';
import 'widgets/metric_tile.dart';
import 'widgets/session_camera_preview.dart';
import '../../widgets/half_court_shot_chart.dart';
import '../session_detail/session_detail_screen.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({
    required this.mode,
    this.showDistanceSetupOnOpen = false,
    super.key,
  });

  final TrainingMode mode;
  final bool showDistanceSetupOnOpen;

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  int makes = 0;
  int misses = 0;
  int streak = 0;
  int _elapsedSeconds = 0;
  final List<int> _makeFlightTimesMs = [];
  final List<int> _missFlightTimesMs = [];
  final List<ShotChartEntry> _shotChart = [];
  bool isTracking = false;
  bool _hasStarted = false;
  bool _isFinishing = false;
  late bool _setupComplete;
  late final ShotDetectorService _shotDetectorService;
  late final ShotEventTracker _shotEventTracker;
  late final SessionStorage _sessionStorage;
  late final AccountStorage _accountStorage;
  late final OnlineApiService _onlineApiService;
  ShotLabAccount? _onlineAccount;
  DateTime? _startedAt;
  String? _sessionId;
  late final StreamSubscription<DetectorStatus> _statusSubscription;
  late final StreamSubscription<DetectionFrame> _frameSubscription;
  late final Timer _sessionTimer;
  DetectorStatus _detectorStatus = DetectorStatus.loading;
  Duration? _processingTime;
  int _processedDetectionFrames = 0;
  int _totalInferenceTimeMs = 0;
  int _ballVisibleFrames = 0;
  int _rimVisibleFrames = 0;
  int _playerVisibleFrames = 0;
  ShotResult? _lastResult;
  CourtCalibration? _courtCalibration;
  CourtZone? _courtZone;
  Offset? _shootingSpot;
  Duration? _lastTrackedFlightTime;

  int get attempts => makes + misses;
  int get percentage => attempts == 0 ? 0 : ((makes / attempts) * 100).round();

  @override
  void initState() {
    super.initState();
    _setupComplete = !widget.showDistanceSetupOnOpen;
    SystemChrome.setPreferredOrientations(
      widget.showDistanceSetupOnOpen
          ? [DeviceOrientation.portraitUp]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
    _sessionStorage = SessionStorage();
    _accountStorage = AccountStorage();
    _onlineApiService = OnlineApiService();
    _accountStorage.load().then((account) => _onlineAccount = account);
    _shotDetectorService = ShotDetectorService();
    _shotEventTracker = ShotEventTracker();
    _statusSubscription = _shotDetectorService.statuses.listen((status) {
      if (mounted) {
        setState(() => _detectorStatus = status);
      }
    });
    _frameSubscription = _shotDetectorService.frames.listen(_handleFrame);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && isTracking) {
        setState(() => _elapsedSeconds += 1);
      }
    });
    _shotDetectorService.initialize();
    if (widget.showDistanceSetupOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runDistanceSetup());
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _sessionTimer.cancel();
    _statusSubscription.cancel();
    _frameSubscription.cancel();
    _shotDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_setupComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('Distance Challenge setup')),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar, size: 64, color: Color(0xFF3D5A80)),
                  SizedBox(height: 16),
                  Text(
                    'Choose your court position and shooting distance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The camera will open in landscape after setup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _finishSession();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SessionCameraPreview(
              onImageAvailable: _shotDetectorService.processCameraImage,
              streamImages:
                  isTracking && _detectorStatus == DetectorStatus.ready,
            ),
            StreamBuilder<DetectionFrame>(
              stream: isTracking ? _shotDetectorService.frames : null,
              builder: (context, snapshot) {
                final frame = snapshot.data;
                final detections =
                    frame?.targetDetections ?? const <YoloDetection>[];

                return DetectionOverlay(
                  detections: detections,
                  sourceAspectRatio: frame?.sourceAspectRatio ?? 16 / 9,
                );
              },
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Column(
                children: [
                  _buildTopControls(),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(
                      label: _statusLabel,
                      icon: _statusIcon,
                      color: _statusColor,
                    ),
                  ),
                  if (!_hasStarted) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Camera ready. Press play to start tracking.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const Spacer(),
                  _buildBottomControls(),
                ],
              ),
            ),
            if (_shotChart.isNotEmpty)
              Positioned(
                right: 12,
                bottom: 12,
                width: 150,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HalfCourtShotChart(
                          shots: _shotChart,
                          showBorder: false,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_shotChart.length} mapped shots',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runDistanceSetup() async {
    if (!mounted) return;
    final spot = await _chooseShootingSpot();
    if (spot == null || !mounted) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    final distanceSelected = await _showDistanceCalibration();
    if (!distanceSelected || !mounted) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (mounted) setState(() => _setupComplete = true);
  }

  Widget _buildTopControls() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CameraIconButton(
          tooltip: _hasStarted ? 'Finish and save session' : 'Back',
          icon: _hasStarted ? Icons.stop_circle_outlined : Icons.arrow_back,
          onPressed: _finishSession,
        ),
        const Spacer(),
        _CameraMetric(label: 'SCORE', value: '$makes / $attempts'),
        const SizedBox(width: 8),
        _CameraMetric(label: 'TIME', value: _elapsedTimeLabel),
        const Spacer(),
        _CameraIconButton(
          tooltip: 'Extended statistics',
          icon: Icons.bar_chart,
          onPressed: _showExtendedStatistics,
        ),
      ],
    );
  }

  Future<void> _finishSession() async {
    if (_isFinishing) {
      return;
    }
    _isFinishing = true;

    if (!_hasStarted) {
      Navigator.of(context).pop(false);
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        final hasAttempts = attempts > 0;
        return AlertDialog(
          title: const Text('Finish session?'),
          content: Text(
            hasAttempts
                ? 'Save $makes makes from $attempts attempts to your history?'
                : 'No shots were recorded. Save this session and its camera '
                    'detection diagnostics so you can review what happened?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Discard'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.save_outlined),
              label: Text(hasAttempts ? 'Save' : 'Save diagnostics'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }
    if (shouldSave == null) {
      _isFinishing = false;
      return;
    }
    if (!shouldSave) {
      Navigator.of(context).pop(false);
      return;
    }

    if (_requiresShootingSpot && _courtZone == null) {
      final selectedSpot = await _chooseShootingSpot();
      if (!mounted) {
        return;
      }
      if (selectedSpot == null) {
        _isFinishing = false;
        return;
      }
    }

    final endedAt = DateTime.now();
    final session = TrainingSession(
      id: _sessionId ?? 'session-${endedAt.microsecondsSinceEpoch}',
      modeTitle: widget.mode.title,
      startedAt:
          _startedAt ?? endedAt.subtract(Duration(seconds: _elapsedSeconds)),
      endedAt: endedAt,
      makes: makes,
      misses: misses,
      durationSeconds: _elapsedSeconds,
      distanceMeters: _courtCalibration?.distanceMeters,
      courtZone: _courtZone,
      makeFlightTimesMs: _makeFlightTimesMs,
      missFlightTimesMs: _missFlightTimesMs,
      processedDetectionFrames: _processedDetectionFrames,
      totalInferenceTimeMs: _totalInferenceTimeMs,
      ballVisibleFrames: _ballVisibleFrames,
      rimVisibleFrames: _rimVisibleFrames,
      playerVisibleFrames: _playerVisibleFrames,
      shotChart: _shotChart,
    );
    await _sessionStorage.saveSession(session);
    final onlineAccount = _onlineAccount;
    if (onlineAccount != null && _onlineApiService.configuration.canSync) {
      try {
        await _onlineApiService.saveSession(onlineAccount, session);
      } on OnlineApiException {
        // Local history remains authoritative when cloud sync is unavailable.
      }
    }

    if (mounted) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      if (!mounted) return;
      Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        ),
        result: true,
      );
    }
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_requiresShootingSpot) ...[
          FilledButton.tonalIcon(
            onPressed: _chooseShootingSpot,
            icon: const Icon(Icons.location_on_outlined),
            label: Text(_courtZone?.label ?? 'Choose spot'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.66),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
        ],
        _TrackingControlButton(
          label: !_hasStarted
              ? 'Start'
              : isTracking
              ? 'Pause'
              : 'Resume',
          tooltip: !_hasStarted
              ? 'Start tracking'
              : isTracking
              ? 'Pause tracking'
              : 'Resume tracking',
          icon: isTracking ? Icons.pause : Icons.play_arrow,
          onPressed: _toggleTracking,
        ),
        if (_hasStarted) ...[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _finishSession,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Finish & save'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE85D04),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleTracking() async {
    if (!_hasStarted && _requiresShootingSpot && _shootingSpot == null) {
      final selected = await _chooseShootingSpot();
      if (selected == null || !mounted) return;
    }
    setState(() {
      if (!_hasStarted) {
        _hasStarted = true;
        _startedAt = DateTime.now();
        _sessionId = 'session-${_startedAt!.microsecondsSinceEpoch}';
        isTracking = true;
      } else {
        isTracking = !isTracking;
      }
      if (!isTracking) {
        _shotEventTracker.reset();
      }
    });
  }

  Future<Offset?> _chooseShootingSpot() async {
    final shouldRestoreLandscape = _setupComplete;
    final wasTracking = isTracking;
    if (wasTracking) {
      setState(() => isTracking = false);
      _shotEventTracker.reset();
    }
    if (shouldRestoreLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return null;
    }
    final spot = await showDialog<Offset>(
      context: context,
      builder: (context) => ShootingSpotPicker(initialPosition: _shootingSpot),
    );
    if (mounted && spot != null) {
      setState(() {
        _shootingSpot = spot;
        _courtZone = courtZoneForPosition(spot.dx, spot.dy);
      });
    }
    if (shouldRestoreLandscape && mounted) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    if (mounted && wasTracking) {
      setState(() => isTracking = true);
    }
    return spot;
  }

  bool get _requiresShootingSpot => widget.mode.requiresCourtSpot;

  void _showExtendedStatistics() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFEFF2F5),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.74,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mode.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ScoreSummary(
                    makes: makes,
                    attempts: attempts,
                    percentage: percentage,
                    elapsedTime: _elapsedTimeLabel,
                  ),
                  const SizedBox(height: 12),
                  _MetricGrid(
                    children: [
                      MetricTile(label: 'Makes', value: '$makes'),
                      MetricTile(label: 'Misses', value: '$misses'),
                      MetricTile(label: 'Attempts', value: '$attempts'),
                      MetricTile(label: 'Shot %', value: '$percentage%'),
                      MetricTile(label: 'Time', value: _elapsedTimeLabel),
                      MetricTile(label: 'Streak', value: '$streak'),
                      MetricTile(label: 'Last shot', value: _lastResultLabel),
                      MetricTile(
                        label: 'Distance',
                        value: _courtCalibration?.displayDistance ?? '--',
                      ),
                      MetricTile(
                        label: 'Court zone',
                        value: _courtZone?.label ?? '--',
                      ),
                      MetricTile(
                        label: 'Tracked flight',
                        value: _lastTrackedFlightTime == null
                            ? '--'
                            : '${_lastTrackedFlightTime!.inMilliseconds} ms',
                      ),
                      MetricTile(
                        label: 'Average inference',
                        value: _averageInferenceTimeMs == null
                            ? '--'
                            : '$_averageInferenceTimeMs ms',
                      ),
                      MetricTile(
                        label: 'Ball visibility',
                        value: _visibilityLabel(_ballVisibleFrames),
                      ),
                      MetricTile(
                        label: 'Rim visibility',
                        value: _visibilityLabel(_rimVisibleFrames),
                      ),
                      MetricTile(
                        label: 'Player visibility',
                        value: _visibilityLabel(_playerVisibleFrames),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showDistanceCalibration();
                          },
                          icon: const Icon(Icons.straighten),
                          label: Text(
                            _courtCalibration == null
                                ? 'Set distance'
                                : 'Change distance',
                          ),
                        ),
                      ),
                      if (_requiresShootingSpot) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _chooseShootingSpot();
                            },
                            icon: const Icon(Icons.location_on_outlined),
                            label: Text(
                              _shootingSpot == null
                                  ? 'Set spot'
                                  : 'Change spot',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showDistanceCalibration() async {
    final selection = await showDialog<Object>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Court distance'),
          children: [
            for (final option in CourtDistancePreset.values)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(option),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sports_basketball),
                  title: Text(option.label),
                  trailing: Text('${option.distanceMeters} m'),
                ),
              ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop(_CalibrationChoice.custom);
              },
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.tune),
                title: Text('Custom distance'),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return false;
    }
    if (selection is CourtDistancePreset) {
      setState(() {
        _courtCalibration = CourtCalibration.fromPreset(selection);
      });
      return true;
    }
    if (selection == _CalibrationChoice.custom) {
      return _showCustomDistanceCalibration();
    }
    return false;
  }

  Future<bool> _showCustomDistanceCalibration() async {
    var distance = _courtCalibration?.distanceMeters ?? 5;
    final selectedDistance = await showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom distance'),
              content: SizedBox(
                width: 360,
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 15,
                        divisions: 56,
                        value: distance,
                        label: '${distance.toStringAsFixed(2)} m',
                        onChanged: (value) {
                          setDialogState(() => distance = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '${distance.toStringAsFixed(2)} m',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(distance),
                  child: const Text('Set'),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted && selectedDistance != null) {
      setState(() {
        _courtCalibration = CourtCalibration.custom(selectedDistance);
      });
      return true;
    }
    return false;
  }

  void _handleFrame(DetectionFrame frame) {
    if (!mounted) {
      return;
    }

    final event = isTracking
        ? _shotEventTracker.process(frame.targetDetections, frame.capturedAt)
        : null;
    final detections = frame.targetDetections;
    setState(() {
      _processingTime = frame.processingTime;
      _processedDetectionFrames += 1;
      _totalInferenceTimeMs += frame.processingTime.inMilliseconds;
      if (detections.any((detection) => detection.label == 'ball')) {
        _ballVisibleFrames += 1;
      }
      if (detections.any((detection) => detection.label == 'rim')) {
        _rimVisibleFrames += 1;
      }
      if (detections.any((detection) => detection.label == 'human')) {
        _playerVisibleFrames += 1;
      }
    });

    if (event != null) {
      _recordDetectedResult(event);
    }
  }

  void _recordDetectedResult(ShotEvent event) {
    final result = event.result;
    final flightTimeMs = event.trackedFlightTime.inMilliseconds;
    setState(() {
      _lastResult = result;
      _lastTrackedFlightTime = event.trackedFlightTime;
      if (result == ShotResult.make) {
        makes += 1;
        streak += 1;
        _makeFlightTimesMs.add(flightTimeMs);
      } else {
        misses += 1;
        streak = 0;
        _missFlightTimesMs.add(flightTimeMs);
      }
      final spot = _shootingSpot;
      if (spot != null) {
        _shotChart.add(
          ShotChartEntry(
            x: spot.dx,
            y: spot.dy,
            made: result == ShotResult.make,
            capturedAt: event.timestamp,
            trackedFlightTimeMs: flightTimeMs,
          ),
        );
      }
    });

    final label = result == ShotResult.make ? 'Make detected' : 'Miss detected';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          duration: const Duration(milliseconds: 900),
        ),
      );

    final onlineAccount = _onlineAccount;
    if (onlineAccount != null && _onlineApiService.configuration.canSync) {
      unawaited(
        _onlineApiService
            .saveShotEvent(
              onlineAccount,
              sessionId: _sessionId!,
              shotId: 'shot-${attempts.toString().padLeft(4, '0')}',
              result: result.name,
              trackedFlightTimeMs: flightTimeMs,
              distanceMeters: _courtCalibration?.distanceMeters,
              courtZone: _courtZone?.name,
              courtX: _shootingSpot?.dx,
              courtY: _shootingSpot?.dy,
            )
            .catchError((_) {}),
      );
    }
  }

  String get _lastResultLabel {
    return switch (_lastResult) {
      ShotResult.make => 'Make',
      ShotResult.miss => 'Miss',
      null => '--',
    };
  }

  int? get _averageInferenceTimeMs => _processedDetectionFrames == 0
      ? null
      : (_totalInferenceTimeMs / _processedDetectionFrames).round();

  String _visibilityLabel(int visibleFrames) {
    if (_processedDetectionFrames == 0) {
      return '--';
    }
    final percentage = (visibleFrames / _processedDetectionFrames * 100)
        .round();
    return '$percentage%';
  }

  String get _elapsedTimeLabel {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _statusLabel {
    if (!_hasStarted) return 'Ready';
    if (!isTracking) return 'Paused';
    return switch (_detectorStatus) {
      DetectorStatus.loading => 'Loading model',
      DetectorStatus.ready =>
        _processingTime == null
            ? 'Live detection'
            : 'Live ${_processingTime!.inMilliseconds}ms',
      DetectorStatus.modelMissing => 'Model needed',
      DetectorStatus.unsupportedModel => 'Model unsupported',
      DetectorStatus.error => 'Detection error',
    };
  }

  IconData get _statusIcon {
    if (!_hasStarted) return Icons.play_arrow;
    if (!isTracking) return Icons.pause;
    return switch (_detectorStatus) {
      DetectorStatus.loading => Icons.hourglass_top,
      DetectorStatus.ready => Icons.videocam,
      DetectorStatus.modelMissing => Icons.download_outlined,
      DetectorStatus.unsupportedModel ||
      DetectorStatus.error => Icons.error_outline,
    };
  }

  Color get _statusColor {
    if (!_hasStarted) return const Color(0xFF00E5FF);
    if (!isTracking) return const Color(0xFFFFC857);
    return switch (_detectorStatus) {
      DetectorStatus.ready => const Color(0xFF2BBD7E),
      DetectorStatus.loading => const Color(0xFF00E5FF),
      DetectorStatus.modelMissing ||
      DetectorStatus.unsupportedModel ||
      DetectorStatus.error => const Color(0xFFFF6B6B),
    };
  }
}

enum _CalibrationChoice { custom }

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 2;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 3 ? 2.35 : 1.85,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({
    required this.makes,
    required this.attempts,
    required this.percentage,
    required this.elapsedTime,
  });

  final int makes;
  final int attempts;
  final int percentage;
  final String elapsedTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryStat(label: 'MAKES', value: '$makes'),
          _SummaryStat(label: 'ATTEMPTS', value: '$attempts'),
          _SummaryStat(label: 'SHOT %', value: '$percentage%'),
          _SummaryStat(label: 'TIME', value: elapsedTime),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraMetric extends StatelessWidget {
  const _CameraMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingControlButton extends StatelessWidget {
  const _TrackingControlButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 46,
        child: IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.62),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
