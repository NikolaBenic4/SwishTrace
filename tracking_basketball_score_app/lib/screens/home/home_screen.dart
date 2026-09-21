import 'package:flutter/material.dart';

import '../../models/training_mode.dart';
import '../../models/training_session.dart';
import '../../services/session_storage.dart';
import '../social/social_screen.dart';
import '../profile/profile_screen.dart';
import '../levels/levels_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/mode_card.dart';
import 'widgets/session_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessionStorage _sessionStorage = SessionStorage();
  late Future<List<TrainingSession>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = _sessionStorage.loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final modes = [
      TrainingMode(
        title: 'Live Shot Tracking',
        subtitle: 'Open the camera and automatically count makes and misses.',
        icon: Icons.center_focus_strong,
        accent: const Color(0xFFE87521),
        metrics: 'Best for a normal shooting workout',
        badge: 'LIVE CAMERA',
        destination: TrainingModeDestination.liveCamera,
        instructions: const [
          'Keep the shooter, ball, and rim visible.',
          'SwishTrace automatically records makes, misses, and flight time.',
          'Press Start and shoot freely without choosing a court spot.',
        ],
      ),
      TrainingMode(
        title: 'Levels',
        subtitle: 'Build your game through 30 progressive shooting challenges.',
        icon: Icons.emoji_events,
        accent: const Color(0xFFD49A19),
        metrics: '3 daily attempts | earn stars and hearts',
        badge: '30 LEVELS',
        destination: TrainingModeDestination.levels,
        instructions: const [
          'Start with the first unlocked challenge and build a streak.',
          'Earn up to 3 stars based on makes, misses, and consistency.',
          'Perfect scores restore one heart, up to three hearts.',
        ],
      ),
      TrainingMode(
        title: 'Form Session',
        subtitle: 'Analyze wrist release and body form with pose tracking.',
        icon: Icons.accessibility_new,
        accent: const Color(0xFF2B7A78),
        metrics: 'Requires the upcoming pose model',
        badge: 'COMING SOON',
        destination: TrainingModeDestination.unavailable,
        instructions: const [
          'This mode needs hand and body keypoints.',
          'The current ball-and-rim model cannot measure form reliably.',
        ],
      ),
      TrainingMode(
        title: 'Distance Challenge',
        subtitle: 'Set a marked distance, then compare shooting by range.',
        icon: Icons.radar,
        accent: const Color(0xFF3D5A80),
        metrics: 'Camera workout with distance setup',
        badge: 'CAMERA + SETUP',
        destination: TrainingModeDestination.distanceCamera,
        instructions: const [
          'First tap your shooting position on the half court.',
          'Then set free-throw, FIBA, NBA, or custom distance.',
          'Shoot from that mark without moving the phone.',
          'Save the session to compare accuracy by range.',
        ],
      ),
      TrainingMode(
        title: 'Friend Battle',
        subtitle: 'Challenge friends and view the weekly leaderboard.',
        icon: Icons.groups_2,
        accent: const Color(0xFF8A4FFF),
        metrics: 'Opens Online—not the camera',
        badge: 'ONLINE',
        destination: TrainingModeDestination.online,
        instructions: const [
          'Sign in to your SwishTrace account.',
          'Add a friend and send a makes challenge.',
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        HomeHeader(onProfilePressed: _openProfile),
        const SizedBox(height: 18),
        FutureBuilder<List<TrainingSession>>(
          future: _sessions,
          builder: (context, snapshot) {
            return SessionSummaryCard(sessions: snapshot.data ?? const []);
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Training modes',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final mode in modes) ...[
          ModeCard(
            mode: mode,
            onSessionSaved: _reloadSessions,
            onOpenOnline: _openOnline,
            onOpenLevels: _openLevels,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _reloadSessions() {
    setState(() {
      _sessions = _sessionStorage.loadSessions();
    });
  }

  void _openOnline() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SocialScreen()));
  }

  void _openLevels() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LevelsScreen()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }
}
