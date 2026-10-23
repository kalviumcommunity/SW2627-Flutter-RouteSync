import 'package:flutter/material.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/models/user_model.dart';
import 'package:routesync/widgets/status_chip.dart';
import 'package:routesync/utils/app_constants.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  const DeliveryDetailsScreen({
    super.key,
    required this.delivery,
    this.executives = const [],
    this.onAssign,
  });

  final DeliveryModel delivery;
  final List<UserModel> executives;
  final Future<void> Function({
    required String deliveryId,
    required String executiveId,
  })?
  onAssign;

  static const _stages = [
    ('Assigned', 'ASSIGNED'),
    ('Picked up', DeliveryStatuses.pickedUp),
    ('Out for delivery', DeliveryStatuses.outForDelivery),
    ('Delivered', DeliveryStatuses.delivered),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = _stages.indexWhere(
      (stage) => stage.$2 == delivery.status.toUpperCase(),
    );
    final failed = delivery.status == DeliveryStatuses.failed;

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
          if (onAssign != null) ...[
            const SizedBox(height: 16),
            _AssignmentEditor(
              delivery: delivery,
              executives: executives,
              onAssign: onAssign!,
            ),
          ],
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

class _AssignmentEditor extends StatefulWidget {
  const _AssignmentEditor({
    required this.delivery,
    required this.executives,
    required this.onAssign,
  });

  final DeliveryModel delivery;
  final List<UserModel> executives;
  final Future<void> Function({
    required String deliveryId,
    required String executiveId,
  })
  onAssign;

  @override
  State<_AssignmentEditor> createState() => _AssignmentEditorState();
}

class _AssignmentEditorState extends State<_AssignmentEditor> {
  late String _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.delivery.assignedExecutiveId;
  }

  Future<void> _save() async {
    if (_selectedId.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onAssign(
        deliveryId: widget.delivery.id,
        executiveId: _selectedId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Assignment saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save assignment: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.executives.isEmpty) {
      return _InfoCard(
        title: 'Assignment',
        icon: Icons.person_search_outlined,
        children: const [Text('No active executives are available.')],
      );
    }
    final selected = widget.executives.any((user) => user.id == _selectedId)
        ? _selectedId
        : widget.executives.first.id;
    if (selected != _selectedId) _selectedId = selected;
    return _InfoCard(
      title: 'Reassign delivery',
      icon: Icons.swap_horiz,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Executive'),
          items: widget.executives
              .map(
                (user) => DropdownMenuItem(
                  value: user.id,
                  child: Text(user.name.isEmpty ? user.email : user.name),
                ),
              )
              .toList(),
          onChanged: _saving
              ? null
              : (value) => setState(() => _selectedId = value!),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save assignment'),
        ),
      ],
    );
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
