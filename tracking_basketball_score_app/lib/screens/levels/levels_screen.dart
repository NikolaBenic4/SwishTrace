import 'package:flutter/material.dart';

import '../../models/level_progress.dart';
import '../../models/training_level.dart';
import '../../services/level_progress_storage.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final LevelProgressStorage _storage = LevelProgressStorage();
  late Future<LevelProgress> _progress;

  @override
  void initState() {
    super.initState();
    _progress = _storage.loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: FutureBuilder<LevelProgress>(
        future: _progress,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final progress = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _ProgressHeader(progress: progress),
              const SizedBox(height: 16),
              for (final level in levelCatalog) ...[
                _LevelCard(
                  level: level,
                  progress: progress,
                  onTap: () => _openLevel(level, progress),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openLevel(TrainingLevel level, LevelProgress progress) async {
    if (level.number != progress.currentLevel || !progress.hasAttemptLeft) {
      return;
    }
    final result = await showDialog<LevelResult>(
      context: context,
      builder: (_) => _LevelAttemptDialog(level: level),
    );
    if (result == null || !mounted) return;

    final updated = progress.applyResult(level, result);
    await _storage.saveProgress(updated);
    if (!mounted) return;
    setState(() {
      _progress = Future.value(updated);
    });
    await showDialog<void>(
      context: context,
      builder: (_) => _ResultDialog(result: result, level: level),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress});

  final LevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.isComplete
                  ? 'All 30 levels complete'
                  : 'Level ${progress.currentLevel} is ready',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.remainingAttempts} attempts left today',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFFD84A4A), size: 20),
                const SizedBox(width: 6),
                Text('${progress.hearts}/3 hearts'),
                const SizedBox(width: 18),
                const Icon(Icons.star, color: Color(0xFFD49A19), size: 20),
                const SizedBox(width: 6),
                Text(
                  '${progress.starsByLevel.values.fold(0, (sum, stars) => sum + stars)} stars',
                ),
              ],
            ),
            if (!progress.hasAttemptLeft) ...[
              const SizedBox(height: 10),
              Text(
                'Come back tomorrow for three fresh attempts.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.progress,
    required this.onTap,
  });

  final TrainingLevel level;
  final LevelProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stars = progress.starsFor(level.number);
    final unlocked = level.number <= progress.currentLevel;
    final active =
        level.number == progress.currentLevel && progress.hasAttemptLeft;
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Colors.black45;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: unlocked
                    ? Text(
                        '${level.number}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      )
                    : const Icon(Icons.lock_outline, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      level.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${level.targetMakes} makes | ${level.attemptLimit} tries',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              _Stars(stars: stars),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 1; index <= 3; index++)
          Icon(
            index <= stars ? Icons.star : Icons.star_border,
            color: const Color(0xFFD49A19),
            size: 18,
          ),
      ],
    );
  }
}

class _LevelAttemptDialog extends StatefulWidget {
  const _LevelAttemptDialog({required this.level});

  final TrainingLevel level;

  @override
  State<_LevelAttemptDialog> createState() => _LevelAttemptDialogState();
}

class _LevelAttemptDialogState extends State<_LevelAttemptDialog> {
  final _makesController = TextEditingController();
  final _missesController = TextEditingController();
  final _streakController = TextEditingController();

  @override
  void dispose() {
    _makesController.dispose();
    _missesController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return AlertDialog(
      title: Text('Level ${level.number}: ${level.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(level.description),
            const SizedBox(height: 14),
            _NumberField(controller: _makesController, label: 'Makes'),
            _NumberField(controller: _missesController, label: 'Misses'),
            _NumberField(controller: _streakController, label: 'Best streak'),
            const SizedBox(height: 4),
            Text(
              'Maximum ${level.attemptLimit} total tries for this level.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Submit attempt')),
      ],
    );
  }

  void _submit() {
    final makes = int.tryParse(_makesController.text) ?? -1;
    final misses = int.tryParse(_missesController.text) ?? -1;
    final bestStreak = int.tryParse(_streakController.text) ?? -1;
    final attempts = makes + misses;
    if (makes < 0 ||
        misses < 0 ||
        bestStreak < 0 ||
        attempts > widget.level.attemptLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter valid totals within ${widget.level.attemptLimit} tries.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      widget.level.score(makes: makes, misses: misses, bestStreak: bestStreak),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.result, required this.level});

  final LevelResult result;
  final TrainingLevel level;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        result.passed ? 'Level ${level.number} passed' : 'Level reset',
      ),
      content: Text(
        result.passed
            ? '${result.stars} stars earned. ${result.stars == 3 ? 'Perfect score: one heart restored.' : 'Keep building your streak.'}'
            : 'Reach ${level.targetMakes} makes with a ${level.requiredStreak}-shot streak within ${level.attemptLimit} tries.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
