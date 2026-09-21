import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.onProfilePressed, super.key});

  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SwishTrace',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Train smarter with live shot feedback.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onProfilePressed,
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profile',
        ),
      ],
    );
  }
}
