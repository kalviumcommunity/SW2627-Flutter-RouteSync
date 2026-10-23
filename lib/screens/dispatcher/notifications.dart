import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _notifications = [
    (
      Icons.report_problem_outlined,
      'New escalation',
      'A delivery issue needs dispatcher attention.',
      'Today',
    ),
    (
      Icons.local_shipping_outlined,
      'Delivery update',
      'An executive has updated a delivery status.',
      'Today',
    ),
    (
      Icons.check_circle_outline,
      'Delivery completed',
      'A delivery was marked as delivered.',
      'Yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preview notifications. Live notification delivery is not connected.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final notification in _notifications) ...[
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                  child: Icon(
                    notification.$1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  notification.$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(notification.$3),
                ),
                trailing: Text(
                  notification.$4,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
