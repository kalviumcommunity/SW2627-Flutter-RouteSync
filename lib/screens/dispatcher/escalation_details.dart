import 'package:flutter/material.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/models/escalation_model.dart';
import 'package:routesync/screens/dispatcher/delivery_details.dart';
import 'package:routesync/widgets/status_chip.dart';

class EscalationDetailsScreen extends StatelessWidget {
  const EscalationDetailsScreen({
    super.key,
    required this.escalation,
    this.delivery,
    required this.onResolve,
  });

  final EscalationModel escalation;
  final DeliveryModel? delivery;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final isOpen = escalation.status.toUpperCase() == 'OPEN';
    return Scaffold(
      appBar: AppBar(title: const Text('Escalation details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            escalation.reason.isEmpty ? 'Escalation' : escalation.reason,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                StatusChip(status: escalation.status),
                StatusChip(status: escalation.priority),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    escalation.description.isEmpty
                        ? 'No additional description provided.'
                        : escalation.description,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Delivery ID',
                    value: delivery?.orderId.isNotEmpty == true
                        ? delivery!.orderId
                        : escalation.deliveryId,
                  ),
                  _DetailRow(
                    label: 'Raised by',
                    value: escalation.raisedBy.isEmpty
                        ? 'Not available'
                        : escalation.raisedBy,
                  ),
                  _DetailRow(
                    label: 'Created',
                    value: _formatDate(escalation.createdAt),
                  ),
                  if (escalation.resolvedAt != null)
                    _DetailRow(
                      label: 'Resolved',
                      value: _formatDate(escalation.resolvedAt),
                    ),
                ],
              ),
            ),
          ),
          if (delivery != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(
                  delivery!.customerName.isEmpty
                      ? 'Customer unavailable'
                      : delivery!.customerName,
                ),
                subtitle: Text(delivery!.city),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        DeliveryDetailsScreen(delivery: delivery!),
                  ),
                ),
              ),
            ),
          ],
          if (isOpen) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _confirmResolve(context),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as resolved'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmResolve(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve escalation?'),
        content: const Text(
          'This will mark the escalation as resolved in the current session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onResolve();
              Navigator.pop(context);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not available';
    return '${value.toLocal().day}/${value.toLocal().month}/${value.toLocal().year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
