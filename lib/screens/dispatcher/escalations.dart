import 'package:flutter/material.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/models/escalation_model.dart';
import 'package:routesync/screens/dispatcher/escalation_details.dart';
import 'package:routesync/widgets/status_chip.dart';

class EscalationsScreen extends StatelessWidget {
  const EscalationsScreen({
    super.key,
    required this.escalations,
    required this.deliveries,
    required this.onResolve,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<EscalationModel> escalations;
  final List<DeliveryModel> deliveries;
  final ValueChanged<String> onResolve;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final openItems = escalations
        .where((item) => item.status.toUpperCase() == 'OPEN')
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Escalations')),
      body: _buildBody(context, openItems),
    );
  }

  Widget _buildBody(BuildContext context, List<EscalationModel> openItems) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage case final message?) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load escalations',
        message: message,
      );
    }
    if (openItems.isEmpty) {
      return const _EmptyState(
        icon: Icons.task_alt,
        title: 'All clear',
        message: 'There are no open escalations to review.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: openItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final escalation = openItems[index];
        final delivery = _findDelivery(escalation);
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => EscalationDetailsScreen(
                  escalation: escalation,
                  delivery: delivery,
                  onResolve: () => onResolve(escalation.id),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          escalation.reason.isEmpty
                              ? 'Delivery issue'
                              : escalation.reason,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusChip(status: escalation.priority),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    escalation.description.isEmpty
                        ? 'No additional description.'
                        : escalation.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 17),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          delivery?.orderId.isNotEmpty == true
                              ? delivery!.orderId
                              : escalation.deliveryId,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _confirmResolve(context, escalation.id),
                        child: const Text('Resolve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DeliveryModel? _findDelivery(EscalationModel escalation) {
    for (final delivery in deliveries) {
      if (delivery.id == escalation.deliveryId) return delivery;
    }
    return null;
  }

  void _confirmResolve(BuildContext context, String escalationId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve escalation?'),
        content: const Text(
          'This will mark the escalation as resolved in Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onResolve(escalationId);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
