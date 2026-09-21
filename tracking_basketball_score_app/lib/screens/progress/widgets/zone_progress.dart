import 'package:flutter/material.dart';

class ZoneProgress extends StatelessWidget {
  const ZoneProgress({
    required this.zone,
    required this.pct,
    required this.makes,
    required this.attempts,
    super.key,
  });

  final String zone;
  final int pct;
  final int makes;
  final int attempts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(zone)),
              Text(attempts == 0 ? 'No shots' : '$makes / $attempts  $pct%'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}
