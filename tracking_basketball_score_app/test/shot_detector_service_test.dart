import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_basketball_score_app/services/shot_detector_service.dart';

void main() {
  test('decodeYoloOutput returns target detections with normalized bounds', () {
    final service = ShotDetectorService(
      config: const YoloModelConfig(
        modelAssetPath: 'model.tflite',
        labelsAssetPath: 'labels.txt',
        inputSize: 640,
        confidenceThreshold: 0.5,
        ballConfidenceThreshold: 0.30,
      ),
    );

    final detections = service.decodeYoloOutput(
      [
        [
          [64, 128, 192, 320, 0.86, 0],
          [300, 120, 340, 160, 0.91, 1],
          [400, 80, 520, 130, 0.93, 2],
        ],
      ],
      const [1, 3, 6],
    );

    expect(detections.map((detection) => detection.label), [
      'rim',
      'human',
      'ball',
    ]);
    expect(detections.first.confidence, 0.93);
    expect(detections.last.left, closeTo(0.1, 0.001));
    expect(detections.last.top, closeTo(0.2, 0.001));
    expect(detections.last.width, closeTo(0.2, 0.001));
    expect(detections.last.height, closeTo(0.3, 0.001));
  });

  test('decodeYoloOutput filters low confidence and unknown classes', () {
    final service = ShotDetectorService(
      config: const YoloModelConfig(
        modelAssetPath: 'model.tflite',
        labelsAssetPath: 'labels.txt',
        inputSize: 640,
        confidenceThreshold: 0.5,
      ),
    );

    final detections = service.decodeYoloOutput(
      [
        [
          [0.1, 0.2, 0.4, 0.8, 0.34, 0],
          [0.3, 0.2, 0.5, 0.4, 0.88, 9],
          [0.45, 0.1, 0.7, 0.2, 0.9, 2],
        ],
      ],
      const [1, 3, 6],
    );

    expect(detections, hasLength(1));
    expect(detections.single.label, 'rim');
  });

  test('uses a lower threshold for small ball detections', () {
    final service = ShotDetectorService(
      config: const YoloModelConfig(
        modelAssetPath: 'model.tflite',
        labelsAssetPath: 'labels.txt',
        inputSize: 640,
        confidenceThreshold: 0.5,
        ballConfidenceThreshold: 0.30,
      ),
    );

    final detections = service.decodeYoloOutput([
      [
        [0.3, 0.2, 0.5, 0.4, 0.31, 0],
      ],
    ], const []);

    expect(detections.map((detection) => detection.label), ['ball']);
  });
}
