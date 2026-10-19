import 'package:flutter/material.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/widgets/status_chip.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  const DeliveryDetailsScreen({super.key, required this.delivery});

  final DeliveryModel delivery;

  static const _stages = [
    ('Assigned', 'ASSIGNED'),
    ('Picked up', 'PICKED_UP'),
    ('In transit', 'IN_TRANSIT'),
    ('Out for delivery', 'OUT_FOR_DELIVERY'),
    ('Delivered', 'DELIVERED'),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = _stages.indexWhere(
      (stage) => stage.$2 == delivery.status.toUpperCase(),
    );
    final failed = delivery.status.toUpperCase() == 'FAILED';

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            delivery.orderId.isEmpty
                ? 'Order ${delivery.id}'
                : delivery.orderId,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(status: delivery.status),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            title: 'Customer',
            icon: Icons.person_outline,
            children: [
              _InfoRow(
                label: 'Name',
                value: _orUnavailable(delivery.customerName),
              ),
              _InfoRow(
                label: 'Phone',
                value: _orUnavailable(delivery.customerPhone),
              ),
              _InfoRow(
                label: 'Address',
                value: [
                  delivery.address,
                  delivery.city,
                ].where((part) => part.isNotEmpty).join(', '),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Assignment',
            icon: Icons.route_outlined,
            children: [
              _InfoRow(
                label: 'Executive',
                value: _orUnavailable(delivery.assignedExecutiveId),
              ),
              _InfoRow(
                label: 'Created',
                value: _formatDate(delivery.createdAt),
              ),
              _InfoRow(
                label: 'Last updated',
                value: _formatDate(delivery.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Delivery timeline',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  for (var index = 0; index < _stages.length; index++)
                    _TimelineStage(
                      title: _stages[index].$1,
                      completed: !failed && activeIndex >= index,
                      isLast: index == _stages.length - 1 && !failed,
                      timestamp: index == 0
                          ? _formatDate(delivery.createdAt)
                          : index == activeIndex
                          ? _formatDate(delivery.updatedAt)
                          : 'Time not available',
                    ),
                  if (failed)
                    _TimelineStage(
                      title: 'Delivery failed',
                      completed: true,
                      isLast: true,
                      isError: true,
                      timestamp: _formatDate(delivery.updatedAt),
                    ),
                  if (activeIndex < 0 && !failed)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Current status: ${delivery.status.replaceAll('_', ' ')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (delivery.failureReason?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Failure reason',
              icon: Icons.error_outline,
              children: [Text(delivery.failureReason!)],
            ),
          ],
          if (delivery.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Notes',
              icon: Icons.notes_outlined,
              children: [Text(delivery.notes!)],
            ),
          ],
        ],
      ),
    );
  }

  static String _orUnavailable(String value) =>
      value.isEmpty ? 'Not available' : value;

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Time not available';
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day}/${local.month}/${local.year} · $hour:$minute $period';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _TimelineStage extends StatelessWidget {
  const _TimelineStage({
    required this.title,
    required this.completed,
    required this.isLast,
    required this.timestamp,
    this.isError = false,
  });

  final String title;
  final bool completed;
  final bool isLast;
  final String timestamp;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : completed
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  isError
                      ? Icons.cancel
                      : completed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: color,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: completed
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timestamp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
