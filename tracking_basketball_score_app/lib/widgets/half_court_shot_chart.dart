import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shot_chart_entry.dart';

class HalfCourtShotChart extends StatelessWidget {
  const HalfCourtShotChart({
    required this.shots,
    this.selectedPosition,
    this.onPositionSelected,
    this.height = 360,
    this.showBorder = true,
    super.key,
  });

  final List<ShotChartEntry> shots;
  final Offset? selectedPosition;
  final ValueChanged<Offset>? onPositionSelected;
  final double height;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 50 / 47,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: onPositionSelected == null
                ? null
                : (details) {
                    onPositionSelected!(
                      Offset(
                        (details.localPosition.dx / constraints.maxWidth).clamp(
                          0,
                          1,
                        ),
                        (details.localPosition.dy / constraints.maxHeight)
                            .clamp(0, 1),
                      ),
                    );
                  },
            child: CustomPaint(
              painter: _HalfCourtPainter(
                shots: shots,
                selectedPosition: selectedPosition,
                lineColor: Theme.of(context).colorScheme.onPrimaryContainer,
                courtColor: const Color(0xFFE8B878),
                showBorder: showBorder,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _HalfCourtPainter extends CustomPainter {
  const _HalfCourtPainter({
    required this.shots,
    required this.selectedPosition,
    required this.lineColor,
    required this.courtColor,
    required this.showBorder,
  });

  final List<ShotChartEntry> shots;
  final Offset? selectedPosition;
  final Color lineColor;
  final Color courtColor;
  final bool showBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final court = Offset.zero & size;
    final background = Paint()..color = courtColor;
    final lines = Paint()
      ..color = lineColor.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.005);

    canvas.drawRRect(
      RRect.fromRectAndRadius(court, Radius.circular(size.width * 0.025)),
      background,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(court, Radius.circular(size.width * 0.025)),
    );

    final hoop = Offset(size.width / 2, size.height * 0.105);
    final scaleX = size.width / 50;
    final scaleY = size.height / 47;

    if (showBorder) {
      canvas.drawRect(court.deflate(lines.strokeWidth / 2), lines);
    }

    final paintRect = Rect.fromLTWH(
      size.width / 2 - 8 * scaleX,
      0,
      16 * scaleX,
      19 * scaleY,
    );
    canvas.drawRect(paintRect, lines);
    final freeThrowCenter = Offset(size.width / 2, paintRect.bottom);
    final freeThrowCircle = Rect.fromCircle(
      center: freeThrowCenter,
      radius: 6 * scaleX,
    );
    canvas.drawArc(freeThrowCircle, 0, math.pi, false, lines);
    canvas.drawArc(
      freeThrowCircle,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = lineColor.withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lines.strokeWidth,
    );

    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.085),
      Offset(size.width * 0.56, size.height * 0.085),
      lines,
    );
    canvas.drawCircle(hoop, 0.75 * scaleX, lines);

    final restrictedRect = Rect.fromCenter(
      center: hoop,
      width: 8 * scaleX,
      height: 8 * scaleY,
    );
    canvas.drawArc(restrictedRect, 0, math.pi, false, lines);

    final threeRadius = 23.75 * scaleX;
    final cornerX = 3 * scaleX;
    final cornerEndY = size.height * 0.295;
    canvas.drawLine(Offset(cornerX, 0), Offset(cornerX, cornerEndY), lines);
    canvas.drawLine(
      Offset(size.width - cornerX, 0),
      Offset(size.width - cornerX, cornerEndY),
      lines,
    );
    final threeRect = Rect.fromCircle(center: hoop, radius: threeRadius);
    final angle = math.acos((size.width / 2 - cornerX) / threeRadius);
    canvas.drawArc(threeRect, angle, math.pi - 2 * angle, false, lines);

    final halfCircle = Rect.fromCircle(
      center: Offset(size.width / 2, size.height),
      radius: 6 * scaleX,
    );
    canvas.drawArc(halfCircle, math.pi, math.pi, false, lines);

    final basketLabel = TextPainter(
      text: TextSpan(
        text: 'BASKET',
        style: TextStyle(
          color: lineColor.withValues(alpha: 0.68),
          fontSize: math.max(8, size.width * 0.024),
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    basketLabel.paint(
      canvas,
      Offset(size.width / 2 - basketLabel.width / 2, size.height * 0.012),
    );

    for (final shot in shots) {
      _drawShot(
        canvas,
        Offset(shot.x * size.width, shot.y * size.height),
        shot.made,
        size,
      );
    }
    final selected = selectedPosition;
    if (selected != null) {
      final point = Offset(selected.dx * size.width, selected.dy * size.height);
      final marker = Paint()
        ..color = const Color(0xFF1D4ED8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, size.width * 0.024, marker);
      canvas.drawCircle(
        point,
        size.width * 0.034,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.008,
      );
    }
    canvas.restore();
  }

  void _drawShot(Canvas canvas, Offset point, bool made, Size size) {
    final radius = size.width * 0.022;
    final fill = Paint()
      ..color = made ? const Color(0xFF16A36A) : const Color(0xFFE24B4B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, radius, fill);
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * 0.22),
    );
  }

  @override
  bool shouldRepaint(_HalfCourtPainter oldDelegate) {
    return oldDelegate.shots != shots ||
        oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.showBorder != showBorder;
  }
}

class ShootingSpotPicker extends StatefulWidget {
  const ShootingSpotPicker({this.initialPosition, super.key});

  final Offset? initialPosition;

  @override
  State<ShootingSpotPicker> createState() => _ShootingSpotPickerState();
}

class _ShootingSpotPickerState extends State<ShootingSpotPicker> {
  Offset? _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final zone = position == null
        ? null
        : courtZoneForPosition(position.dx, position.dy);
    final screen = MediaQuery.sizeOf(context);
    final isLandscape = screen.width > screen.height;
    final instructions = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tap your shooting position on the court.'),
        const SizedBox(height: 12),
        Text(
          zone?.label ?? 'No spot selected',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
    final chart = HalfCourtShotChart(
      shots: const [],
      selectedPosition: position,
      onPositionSelected: (value) => setState(() => _position = value),
    );
    final availableHeight = math.min(
      screen.height * 0.58,
      isLandscape ? 360.0 : 520.0,
    );
    final courtHeight = isLandscape
        ? availableHeight
        : math.min(screen.height * 0.23, 180.0);
    return AlertDialog(
      title: const Text('Shooting spot'),
      content: SizedBox(
        width: isLandscape
            ? math.min(screen.width * 0.72, 760)
            : math.min(screen.width * 0.82, 430),
        height: isLandscape ? availableHeight : null,
        child: isLandscape
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final instructionsWidth = math.min(
                    210.0,
                    constraints.maxWidth * 0.36,
                  );
                  return Row(
                    children: [
                      SizedBox(width: instructionsWidth, child: instructions),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            height: math.min(
                              courtHeight,
                              (constraints.maxWidth - instructionsWidth - 14) *
                                  47 /
                                  50,
                            ),
                            child: chart,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  instructions,
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final fittedHeight = math.min(
                        courtHeight,
                        constraints.maxWidth * 47 / 50,
                      );
                      return Center(
                        child: SizedBox(height: fittedHeight, child: chart),
                      );
                    },
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: position == null
              ? null
              : () => Navigator.pop(context, position),
          child: const Text('Use this spot'),
        ),
      ],
    );
  }
}

class ShotChartLegend extends StatelessWidget {
  const ShotChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Color(0xFF16A36A), label: 'Make'),
        SizedBox(width: 20),
        _LegendItem(color: Color(0xFFE24B4B), label: 'Miss'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
