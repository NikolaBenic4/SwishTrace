import 'package:flutter/material.dart';

import '../../../models/training_mode.dart';
import '../../live_session/live_session_screen.dart';

class ModeCard extends StatelessWidget {
  const ModeCard({
    required this.mode,
    this.onSessionSaved,
    this.onOpenOnline,
    this.onOpenLevels,
    super.key,
  });

  final TrainingMode mode;
  final VoidCallback? onSessionSaved;
  final VoidCallback? onOpenOnline;
  final VoidCallback? onOpenLevels;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openMode(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: mode.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(mode.icon, color: mode.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mode.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: mode.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            mode.badge,
                            style: TextStyle(
                              color: mode.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.58),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mode.metrics,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: mode.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                mode.destination == TrainingModeDestination.unavailable
                    ? Icons.lock_outline
                    : Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMode(BuildContext context) async {
    switch (mode.destination) {
      case TrainingModeDestination.online:
        onOpenOnline?.call();
        return;
      case TrainingModeDestination.levels:
        onOpenLevels?.call();
        return;
      case TrainingModeDestination.unavailable:
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => _ModeExplanation(mode: mode),
        );
        return;
      case TrainingModeDestination.liveCamera:
      case TrainingModeDestination.distanceCamera:
        final shouldStart = await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: true,
          builder: (context) => _ModeExplanation(mode: mode, canStart: true),
        );
        if (shouldStart != true || !context.mounted) return;
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => LiveSessionScreen(
              mode: mode,
              showDistanceSetupOnOpen:
                  mode.destination == TrainingModeDestination.distanceCamera,
            ),
          ),
        );
        if (saved == true) onSessionSaved?.call();
        return;
    }
  }
}

class _ModeExplanation extends StatelessWidget {
  const _ModeExplanation({required this.mode, this.canStart = false});

  final TrainingMode mode;
  final bool canStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mode.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(mode.subtitle),
            const SizedBox(height: 16),
            for (final instruction in mode.instructions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: mode.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(instruction)),
                  ],
                ),
              ),
            if (canStart) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Open camera'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
