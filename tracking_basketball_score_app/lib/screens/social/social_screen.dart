import 'package:flutter/material.dart';

import '../../models/online_models.dart';
import '../../services/account_storage.dart';
import '../../services/online_api_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _storage = AccountStorage();
  final _api = OnlineApiService();
  late Future<ShotLabAccount?> _account;

  @override
  void initState() {
    super.initState();
    _account = _storage.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShotLabAccount?>(
      future: _account,
      builder: (context, snapshot) {
        final account = snapshot.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Text(
              'Online',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              account == null
                  ? 'Sign in to sync sessions and challenge friends.'
                  : account.email,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (account == null)
              _AccountCard(
                configured: _api.configuration.canAuthenticate,
                onAuthenticate: _authenticate,
              )
            else ...[
              _AccountSummary(
                account: account,
                cloudConfigured: _api.configuration.canSync,
                onSignOut: _signOut,
              ),
              const SizedBox(height: 12),
              _FriendsCard(api: _api, account: account),
              const SizedBox(height: 12),
              _LeaderboardCard(api: _api, account: account),
            ],
          ],
        );
      },
    );
  }

  Future<void> _authenticate({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    try {
      final account = createAccount
          ? await _api.signUp(email, password)
          : await _api.signIn(email, password);
      await _storage.save(account);
      if (mounted) setState(() => _account = Future.value(account));
    } on OnlineApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _signOut() async {
    await _storage.clear();
    if (mounted) setState(() => _account = Future.value());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountCard extends StatefulWidget {
  const _AccountCard({required this.configured, required this.onAuthenticate});

  final bool configured;
  final Future<void> Function({
    required String email,
    required String password,
    required bool createAccount,
  })
  onAuthenticate;

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SwishTrace account',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            if (!widget.configured) ...[
              const SizedBox(height: 10),
              const Text(
                'Firebase is not configured in this build. See docs/ONLINE_SETUP.md.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _submit(false),
                    child: const Text('Sign in'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _busy ? null : () => _submit(true),
                    child: const Text('Create account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(bool createAccount) async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) return;
    setState(() => _busy = true);
    await widget.onAuthenticate(
      email: _email.text,
      password: _password.text,
      createAccount: createAccount,
    );
    if (mounted) setState(() => _busy = false);
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({
    required this.account,
    required this.cloudConfigured,
    required this.onSignOut,
  });

  final ShotLabAccount account;
  final bool cloudConfigured;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(account.email),
        subtitle: Text(
          cloudConfigured ? 'Cloud sync ready' : 'Cloud URL needed',
        ),
        trailing: TextButton(
          onPressed: onSignOut,
          child: const Text('Sign out'),
        ),
      ),
    );
  }
}

class _FriendsCard extends StatefulWidget {
  const _FriendsCard({required this.api, required this.account});
  final OnlineApiService api;
  final ShotLabAccount account;

  @override
  State<_FriendsCard> createState() => _FriendsCardState();
}

class _FriendsCardState extends State<_FriendsCard> {
  late Future<List<FriendProfile>> _friends = _load();

  Future<List<FriendProfile>> _load() => widget.api.loadFriends(widget.account);

  @override
  Widget build(BuildContext context) {
    return _OnlineListCard<FriendProfile>(
      title: 'Friends',
      future: _friends,
      emptyLabel: 'No friends yet.',
      itemBuilder: (friend) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person_outline),
        title: Text(friend.displayName),
        subtitle: Text('${friend.points} points'),
        trailing: IconButton(
          tooltip: 'Challenge to 25 makes',
          onPressed: () async {
            await widget.api.createChallenge(
              widget.account,
              friendUserId: friend.userId,
              targetMakes: 25,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Challenge sent')));
            }
          },
          icon: const Icon(Icons.emoji_events_outlined),
        ),
      ),
      action: IconButton(
        tooltip: 'Add friend',
        onPressed: _addFriend,
        icon: const Icon(Icons.person_add_alt),
      ),
    );
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add friend'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Friend email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty) return;
    await widget.api.addFriend(widget.account, email);
    if (mounted) setState(() => _friends = _load());
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.api, required this.account});
  final OnlineApiService api;
  final ShotLabAccount account;

  @override
  Widget build(BuildContext context) {
    return _OnlineListCard<LeaderboardEntry>(
      title: 'Weekly leaderboard',
      future: api.loadLeaderboard(account),
      emptyLabel: 'No ranked players yet.',
      itemBuilder: (entry) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Text('${entry.rank}')),
        title: Text(entry.displayName),
        trailing: Text(
          '${entry.points} pts',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _OnlineListCard<T> extends StatelessWidget {
  const _OnlineListCard({
    required this.title,
    required this.future,
    required this.emptyLabel,
    required this.itemBuilder,
    this.action,
  });

  final String title;
  final Future<List<T>> future;
  final String emptyLabel;
  final Widget Function(T item) itemBuilder;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            FutureBuilder<List<T>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(emptyLabel),
                  );
                }
                return Column(
                  children: snapshot.data!.map(itemBuilder).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
