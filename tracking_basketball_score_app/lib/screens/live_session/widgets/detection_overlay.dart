import 'package:flutter/material.dart';

import '../../../services/shot_detector_service.dart';

class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    required this.detections,
    required this.sourceAspectRatio,
    super.key,
  });

  final Iterable<YoloDetection> detections;
  final double sourceAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overlaySize = Size(constraints.maxWidth, constraints.maxHeight);
        final overlayAspectRatio = overlaySize.width / overlaySize.height;
        final sourceDrawWidth = sourceAspectRatio >= overlayAspectRatio
            ? overlaySize.height * sourceAspectRatio
            : overlaySize.width;
        final sourceDrawHeight = sourceAspectRatio >= overlayAspectRatio
            ? overlaySize.height
            : overlaySize.width / sourceAspectRatio;
        final horizontalOffset = (overlaySize.width - sourceDrawWidth) / 2;
        final verticalOffset = (overlaySize.height - sourceDrawHeight) / 2;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final detection in detections)
                Positioned(
                  left: horizontalOffset + detection.left * sourceDrawWidth,
                  top: verticalOffset + detection.top * sourceDrawHeight,
                  width: detection.width * sourceDrawWidth,
                  height: detection.height * sourceDrawHeight,
                  child: detection.isBall
                      ? BallDot(confidence: detection.confidence)
                      : DetectionBox(
                          label: detection.label,
                          confidence: detection.confidence,
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class DetectionBox extends StatelessWidget {
  const DetectionBox({required this.label, this.confidence, super.key});

  final String label;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF00E5FF)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            _labelText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  String get _labelText {
    final score = confidence;
    if (score == null) {
      return label;
    }

    return '$label ${(score * 100).round()}%';
  }
}

class BallDot extends StatelessWidget {
  const BallDot({this.confidence, super.key});

  final double? confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A1A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xAAFF7A1A), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: confidence == null
          ? null
          : Center(
              child: Text(
                '${(confidence! * 100).round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
