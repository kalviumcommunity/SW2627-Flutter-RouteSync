import 'package:flutter/material.dart';
import 'package:routesync/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user, required this.onLogout});

  final UserModel user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? 'D'
        : user.name.trim().substring(0, 1).toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    child: Text(
                      initial,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name.isEmpty ? 'Dispatcher' : user.name,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.role.isEmpty ? 'Dispatcher' : user.role,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ProfileItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email.isEmpty ? 'Not available' : user.email,
          ),
          _ProfileItem(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: user.city.isEmpty ? 'Not available' : user.city,
          ),
          _ProfileItem(
            icon: user.active ? Icons.verified_user_outlined : Icons.block,
            label: 'Account status',
            value: user.active ? 'Active' : 'Inactive',
          ),
          const SizedBox(height: 26),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You can connect this action to the authentication service when it is available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onLogout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
