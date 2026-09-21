import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloModelConfig {
  final String modelAssetPath;
  final String labelsAssetPath;
  final int inputSize;
  final double confidenceThreshold;
  final double ballConfidenceThreshold;
  final double rimConfidenceThreshold;

  const YoloModelConfig({
    required this.modelAssetPath,
    required this.labelsAssetPath,
    required this.inputSize,
    required this.confidenceThreshold,
    this.ballConfidenceThreshold = 0.35,
    this.rimConfidenceThreshold = 0.4,
  });
}

class YoloDetection {
  final double left, top, width, height, confidence;
  final String label;
  final bool isBall;

  double get right => left + width;
  double get bottom => top + height;

  YoloDetection({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
    required this.label,
    this.isBall = false,
  });
}

class DetectionFrame {
  final Iterable<YoloDetection> targetDetections;
  final double sourceAspectRatio;
  final Duration processingTime;
  final DateTime capturedAt;

  DetectionFrame(
    this.targetDetections, {
    required this.sourceAspectRatio,
    required this.processingTime,
    required this.capturedAt,
  });
}

enum DetectorStatus { loading, ready, modelMissing, unsupportedModel, error }

class ShotDetectorService {
  ShotDetectorService({
    this.config = const YoloModelConfig(
      modelAssetPath: 'assets/models/yolov10n_shotlab.tflite',
      labelsAssetPath: 'assets/models/labels.txt',
      inputSize: 640,
      confidenceThreshold: 0.5,
      ballConfidenceThreshold: 0.30,
      rimConfidenceThreshold: 0.4,
    ),
    this.minimumFrameInterval = const Duration(milliseconds: 120),
  });

  final YoloModelConfig config;
  final Duration minimumFrameInterval;

  static const List<String> _defaultLabels = ['ball', 'human', 'rim'];

  final _frames = StreamController<DetectionFrame>.broadcast();
  final _statuses = StreamController<DetectorStatus>.broadcast();

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  Delegate? _hardwareDelegate;
  DetectorStatus _status = DetectorStatus.loading;
  bool _isProcessing = false;
  bool _isDisposed = false;
  DateTime? _lastFrameStartedAt;

  Stream<DetectionFrame> get frames => _frames.stream;
  Stream<DetectorStatus> get statuses => _statuses.stream;
  DetectorStatus get status => _status;
  bool get isReady => _status == DetectorStatus.ready;

  Future<void> initialize() async {
    _setStatus(DetectorStatus.loading);
    try {
      final options = InterpreterOptions()..threads = 4;
      Delegate? hardwareDelegate;
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          hardwareDelegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(isPrecisionLossAllowed: true),
          );
          options.addDelegate(hardwareDelegate);
        } catch (_) {
          options.useNnApiForAndroid = true;
        }
      }
      late final Interpreter interpreter;
      try {
        interpreter = await Interpreter.fromAsset(
          config.modelAssetPath,
          options: options,
        );
      } catch (_) {
        hardwareDelegate?.delete();
        hardwareDelegate = null;
        final fallbackOptions = InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true;
        interpreter = await Interpreter.fromAsset(
          config.modelAssetPath,
          options: fallbackOptions,
        );
        fallbackOptions.delete();
      }
      options.delete();
      _hardwareDelegate = hardwareDelegate;
      final input = interpreter.getInputTensor(0);
      final output = interpreter.getOutputTensor(0);

      if (!_isSupportedInput(input) || !_isSupportedOutput(output)) {
        interpreter.close();
        hardwareDelegate?.delete();
        _setStatus(DetectorStatus.unsupportedModel);
        return;
      }

      _interpreter = interpreter;
      _isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
      );
      _setStatus(DetectorStatus.ready);
    } catch (error) {
      _hardwareDelegate?.delete();
      _hardwareDelegate = null;
      debugPrint('Shot detector initialization failed: $error');
      final message = error.toString().toLowerCase();
      _setStatus(
        message.contains('asset') || message.contains('unable to load')
            ? DetectorStatus.modelMissing
            : DetectorStatus.error,
      );
    }
  }

  Future<void> processCameraImage(
    CameraImage image,
    int rotationDegrees,
  ) async {
    final interpreter = _interpreter;
    final isolateInterpreter = _isolateInterpreter;
    final now = DateTime.now();
    final lastFrameStartedAt = _lastFrameStartedAt;
    if (_isDisposed ||
        _isProcessing ||
        interpreter == null ||
        isolateInterpreter == null ||
        !isReady ||
        (lastFrameStartedAt != null &&
            now.difference(lastFrameStartedAt) < minimumFrameInterval)) {
      return;
    }

    _isProcessing = true;
    _lastFrameStartedAt = now;
    final stopwatch = Stopwatch()..start();
    try {
      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final inputType = inputTensor.type;
      final inputScale = inputTensor.params.scale;
      final inputZeroPoint = inputTensor.params.zeroPoint;
      final fallbackInputSize = config.inputSize;
      final frameData = _CameraFrameData.fromCameraImage(
        image,
        rotationDegrees,
      );
      final inputBytes = await Isolate.run(
        () => _cameraFrameToInput(
          frameData,
          inputShape,
          inputType,
          inputScale,
          inputZeroPoint,
          fallbackInputSize,
        ),
      );
      final output = _emptyTensor(outputTensor.shape, outputTensor.type);
      await isolateInterpreter.run(inputBytes, output);

      final rawOutput = _flattenTensor(
        output,
        outputTensor.type,
        outputTensor.params.scale,
        outputTensor.params.zeroPoint,
      );
      final detections = decodeYoloOutput([
        _rowsFromOutput(rawOutput, outputTensor.shape),
      ], const []);

      if (!_isDisposed) {
        _frames.add(
          DetectionFrame(
            detections,
            sourceAspectRatio: frameData.rotatedAspectRatio,
            processingTime: stopwatch.elapsed,
            capturedAt: now,
          ),
        );
      }
    } catch (error) {
      debugPrint('Shot detector frame failed: $error');
      _setStatus(DetectorStatus.error);
    } finally {
      stopwatch.stop();
      _isProcessing = false;
    }
  }

  /// Expected detection rows: [x1, y1, x2, y2, confidence, classIndex].
  Iterable<YoloDetection> decodeYoloOutput(
    List<dynamic> rawOutputs,
    List<int> anchorCounts,
  ) {
    final detectionsRaw = <List<num>>[];
    if (rawOutputs.isNotEmpty && rawOutputs.first is List) {
      for (final item in rawOutputs.first as List) {
        if (item is List && item.length >= 6) {
          detectionsRaw.add(List<num>.from(item));
        }
      }
    }

    final detections = <YoloDetection>[];
    for (final detection in detectionsRaw) {
      final confidence = detection[4].toDouble();
      final classId = detection[5].toInt();
      if (classId < 0 || classId >= _defaultLabels.length) {
        continue;
      }
      final label = _defaultLabels[classId];
      final minimumConfidence = switch (label) {
        'ball' => config.ballConfidenceThreshold,
        'rim' => config.rimConfidenceThreshold,
        _ => config.confidenceThreshold,
      };
      if (confidence < minimumConfidence) continue;

      final coordinatesAreNormalized = detection
          .take(4)
          .every((coordinate) => coordinate.abs() <= 1);
      final scale = coordinatesAreNormalized ? 1.0 : config.inputSize;
      final left = (detection[0] / scale).toDouble().clamp(0.0, 1.0);
      final top = (detection[1] / scale).toDouble().clamp(0.0, 1.0);
      final right = (detection[2] / scale).toDouble().clamp(0.0, 1.0);
      final bottom = (detection[3] / scale).toDouble().clamp(0.0, 1.0);
      detections.add(
        YoloDetection(
          left: left,
          top: top,
          width: math.max(0, right - left),
          height: math.max(0, bottom - top),
          confidence: confidence,
          label: label,
          isBall: label == 'ball',
        ),
      );
    }

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections;
  }

  List<List<num>> _rowsFromOutput(List<num> values, List<int> shape) {
    final dimensions = shape.where((dimension) => dimension > 1).toList();
    if (dimensions.length != 2 || !dimensions.contains(6)) {
      throw UnsupportedError('Expected a YOLO output shaped [1, N, 6].');
    }

    final rowCount = dimensions.first == 6 ? dimensions.last : dimensions.first;
    final isTransposed = dimensions.first == 6;

    return List.generate(rowCount, (row) {
      return List.generate(6, (column) {
        final index = isTransposed ? column * rowCount + row : row * 6 + column;
        return values[index];
      });
    });
  }

  static Uint8List _cameraFrameToInput(
    _CameraFrameData image,
    List<int> shape,
    TensorType inputType,
    double quantizationScale,
    int quantizationZeroPoint,
    int fallbackInputSize,
  ) {
    final height = shape.length == 4 ? shape[1] : fallbackInputSize;
    final width = shape.length == 4 ? shape[2] : fallbackInputSize;
    final channels = shape.length == 4 ? shape[3] : 3;
    if (channels != 3) {
      throw UnsupportedError('Only RGB model inputs are supported.');
    }

    final elementCount = width * height * channels;
    final bytes = switch (inputType) {
      TensorType.float32 => Float32List(elementCount).buffer.asUint8List(),
      TensorType.uint8 || TensorType.int8 => Uint8List(elementCount),
      _ => throw UnsupportedError('Unsupported input tensor type.'),
    };
    final floatValues = inputType == TensorType.float32
        ? bytes.buffer.asFloat32List()
        : null;
    final rotatedWidth = image.rotatedWidth;
    final rotatedHeight = image.rotatedHeight;

    for (var y = 0; y < height; y++) {
      final rotatedY = y * rotatedHeight ~/ height;
      for (var x = 0; x < width; x++) {
        final rotatedX = x * rotatedWidth ~/ width;
        final sourcePoint = image.sourcePoint(rotatedX, rotatedY);
        final rgb = image.pixelRgb(sourcePoint.$1, sourcePoint.$2);
        final offset = (y * width + x) * 3;

        if (floatValues != null) {
          floatValues[offset] = rgb.$1 / 255;
          floatValues[offset + 1] = rgb.$2 / 255;
          floatValues[offset + 2] = rgb.$3 / 255;
        } else if (inputType == TensorType.int8) {
          final scale = quantizationScale == 0 ? 1.0 : quantizationScale;
          bytes[offset] = ((rgb.$1 / 255) / scale + quantizationZeroPoint)
              .round()
              .clamp(-128, 127)
              .toUnsigned(8);
          bytes[offset + 1] = ((rgb.$2 / 255) / scale + quantizationZeroPoint)
              .round()
              .clamp(-128, 127)
              .toUnsigned(8);
          bytes[offset + 2] = ((rgb.$3 / 255) / scale + quantizationZeroPoint)
              .round()
              .clamp(-128, 127)
              .toUnsigned(8);
        } else {
          bytes[offset] = rgb.$1;
          bytes[offset + 1] = rgb.$2;
          bytes[offset + 2] = rgb.$3;
        }
      }
    }
    return bytes;
  }

  Object _emptyTensor(List<int> shape, TensorType type, [int depth = 0]) {
    if (depth == shape.length - 1) {
      return switch (type) {
        TensorType.float32 => List<double>.filled(shape[depth], 0),
        TensorType.uint8 ||
        TensorType.int8 => List<int>.filled(shape[depth], 0),
        _ => throw UnsupportedError('Unsupported output tensor type.'),
      };
    }
    return List.generate(
      shape[depth],
      (_) => _emptyTensor(shape, type, depth + 1),
    );
  }

  List<num> _flattenTensor(
    Object value,
    TensorType type,
    double quantizationScale,
    int quantizationZeroPoint,
  ) {
    final flattened = <num>[];

    void addValue(Object item) {
      if (item is List) {
        for (final child in item) {
          addValue(child);
        }
      } else if (item is num) {
        flattened.add(item);
      }
    }

    addValue(value);
    if (type == TensorType.float32) {
      return flattened;
    }

    final scale = quantizationScale == 0 ? 1.0 : quantizationScale;
    return flattened
        .map((item) => (item - quantizationZeroPoint) * scale)
        .toList(growable: false);
  }

  bool _isSupportedInput(Tensor tensor) {
    return tensor.shape.length == 4 &&
        tensor.shape.last == 3 &&
        {
          TensorType.float32,
          TensorType.uint8,
          TensorType.int8,
        }.contains(tensor.type);
  }

  bool _isSupportedOutput(Tensor tensor) {
    return tensor.shape.contains(6) &&
        {
          TensorType.float32,
          TensorType.uint8,
          TensorType.int8,
        }.contains(tensor.type);
  }

  void _setStatus(DetectorStatus status) {
    if (_isDisposed || _status == status) {
      return;
    }
    _status = status;
    _statuses.add(status);
  }

  void dispose() {
    _isDisposed = true;
    unawaited(_isolateInterpreter?.close());
    _interpreter?.close();
    _hardwareDelegate?.delete();
    _frames.close();
    _statuses.close();
  }
}

class _CameraFrameData {
  _CameraFrameData({
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.format,
    required this.planes,
  });

  factory _CameraFrameData.fromCameraImage(
    CameraImage image,
    int rotationDegrees,
  ) {
    return _CameraFrameData(
      width: image.width,
      height: image.height,
      rotationDegrees: rotationDegrees % 360,
      format: image.format.group,
      planes: [
        for (final plane in image.planes)
          _CameraPlaneData(
            bytes: Uint8List.fromList(plane.bytes),
            bytesPerRow: plane.bytesPerRow,
            bytesPerPixel: plane.bytesPerPixel ?? 1,
          ),
      ],
    );
  }

  final int width;
  final int height;
  final int rotationDegrees;
  final ImageFormatGroup format;
  final List<_CameraPlaneData> planes;

  int get rotatedWidth =>
      rotationDegrees == 90 || rotationDegrees == 270 ? height : width;
  int get rotatedHeight =>
      rotationDegrees == 90 || rotationDegrees == 270 ? width : height;
  double get rotatedAspectRatio => rotatedWidth / rotatedHeight;

  (int, int) sourcePoint(int rotatedX, int rotatedY) {
    return switch (rotationDegrees) {
      90 => (rotatedY, height - 1 - rotatedX),
      180 => (width - 1 - rotatedX, height - 1 - rotatedY),
      270 => (width - 1 - rotatedY, rotatedX),
      _ => (rotatedX, rotatedY),
    };
  }

  (int, int, int) pixelRgb(int x, int y) {
    if (format == ImageFormatGroup.bgra8888) {
      final plane = planes.first;
      final offset = y * plane.bytesPerRow + x * 4;
      return (
        plane.bytes[offset + 2],
        plane.bytes[offset + 1],
        plane.bytes[offset],
      );
    }

    if (planes.length < 3) {
      throw UnsupportedError('Expected a YUV420 or BGRA camera image.');
    }

    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];
    final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x];
    final uvIndex =
        (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel;
    final uValue = uPlane.bytes[uvIndex] - 128;
    final vValue = vPlane.bytes[uvIndex] - 128;

    return (
      (yValue + 1.402 * vValue).round().clamp(0, 255),
      (yValue - 0.344136 * uValue - 0.714136 * vValue).round().clamp(0, 255),
      (yValue + 1.772 * uValue).round().clamp(0, 255),
    );
  }
}

class _CameraPlaneData {
  const _CameraPlaneData({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}
