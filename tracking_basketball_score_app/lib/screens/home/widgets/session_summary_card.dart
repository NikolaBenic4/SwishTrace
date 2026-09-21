import 'package:flutter/material.dart';

import '../../../models/training_session.dart';

class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({required this.sessions, super.key});

  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todaySessions = sessions.where((session) {
      final endedAt = session.endedAt.toLocal();
      return endedAt.year == now.year &&
          endedAt.month == now.month &&
          endedAt.day == now.day;
    }).toList();
    final shots = todaySessions.fold(
      0,
      (total, session) => total + session.attempts,
    );
    final makes = todaySessions.fold(
      0,
      (total, session) => total + session.makes,
    );
    final percentage = shots == 0 ? 0 : (makes / shots * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFFFC857)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shots == 0
                      ? 'No tracked sessions today'
                      : 'Today: $percentage% shooting across '
                            '${todaySessions.length} sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(label: 'Shots', value: '$shots'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(label: 'Makes', value: '$makes'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Sessions',
                  value: '${todaySessions.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
