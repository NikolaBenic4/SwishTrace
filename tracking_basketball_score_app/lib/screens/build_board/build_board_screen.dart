import 'package:flutter/material.dart';

import '../../models/build_task.dart';

class BuildBoardScreen extends StatelessWidget {
  const BuildBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTasks = [
      const BuildTask(
        title: '20-shot court validation',
        status: 'Ready',
        area: 'QA',
        priority: 'High',
        note: 'Run COURT_VALIDATION.md before changing scoring thresholds.',
        icon: Icons.fact_check_outlined,
      ),
      const BuildTask(
        title: 'Threshold tuning',
        status: 'Blocked',
        area: 'Tracking',
        priority: 'High',
        note: 'Needs court validation results and false-positive notes.',
        icon: Icons.tune,
      ),
    ];
    final localTasks = [
      const BuildTask(
        title: 'On-device tracking',
        status: 'Done',
        area: 'AI',
        priority: 'High',
        note: 'Camera, YOLO inference, overlays, and shot events are wired.',
        icon: Icons.memory,
      ),
      const BuildTask(
        title: 'Training intelligence',
        status: 'Done',
        area: 'Analytics',
        priority: 'Medium',
        note:
            'Progress, weak-zone drills, quests, points, and badges use saved sessions.',
        icon: Icons.insights,
      ),
      const BuildTask(
        title: 'Automatic court distance',
        status: 'Done',
        area: 'Tracking',
        priority: 'Medium',
        note:
            'Guided two-point visual calibration is the recommended first upgrade.',
        icon: Icons.straighten,
      ),
    ];
    final onlineTasks = [
      const BuildTask(
        title: 'User accounts',
        status: 'Ready',
        area: 'Backend',
        priority: 'High',
        note:
            'Firebase email auth is implemented; add deployment configuration.',
        icon: Icons.account_circle_outlined,
      ),
      const BuildTask(
        title: 'Friends and leaderboards',
        status: 'Ready',
        area: 'Social',
        priority: 'Medium',
        note:
            'Mobile UI and backend endpoints are implemented and await deployment.',
        icon: Icons.groups_outlined,
      ),
      const BuildTask(
        title: 'Serverless session API',
        status: 'Ready',
        area: 'Backend',
        priority: 'High',
        note:
            'SAM stack, Lambda handlers, DynamoDB indexes, and quest job are ready.',
        icon: Icons.cloud_outlined,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          'Build board',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Current project status from the roadmap, grouped by what can move now and what waits for court or backend work.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 14),
        _BuildSection(title: 'Current Focus', tasks: currentTasks),
        _BuildSection(title: 'Local App', tasks: localTasks),
        _BuildSection(title: 'Online Mode', tasks: onlineTasks),
      ],
    );
  }
}

class _BuildSection extends StatelessWidget {
  const _BuildSection({required this.title, required this.tasks});

  final String title;
  final List<BuildTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          for (final task in tasks) ...[
            _BuildTaskCard(task: task),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _BuildTaskCard extends StatelessWidget {
  const _BuildTaskCard({required this.task});

  final BuildTask task;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(task.icon, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _StatusPill(label: task.status, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.note,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(label: task.area),
                      _MetaPill(label: task.priority),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Done' => const Color(0xFF2BBD7E),
      'Ready' => const Color(0xFFE87521),
      'Blocked' => const Color(0xFFE05252),
      'Research' => const Color(0xFF4D7CFE),
      'Deferred' => const Color(0xFF7A7F87),
      _ => const Color(0xFF6B5DD3),
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
