import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_incident_reporting_app/Screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userRole;
  final bool showAppBar;

  const ProfileScreen({
    super.key,
    required this.userRole,
    this.showAppBar = true,
  });

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return '?';

    final nameParts = trimmedName.split(RegExp(r'\s+'));
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts.first[0].toUpperCase();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to sign out: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email available';
    final fallbackName =
        user?.email?.split('@').first.replaceAll('.', ' ') ?? '';
    final cleanName = fallbackName
        .split(' ')
        .map(
          (str) =>
              str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : '',
        )
        .join(' ')
        .trim();

    final displayName = user?.displayName?.trim();
    final finalDisplayName = displayName?.isNotEmpty == true
        ? displayName!
        : (cleanName.isNotEmpty ? cleanName : 'User');
    final roleLabel = userRole == 'staff' ? 'Staff' : 'Student';

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Profile'),
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _getInitials(finalDisplayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              finalDisplayName,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              roleLabel,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Account type'),
                  subtitle: Text(roleLabel),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
