import 'package:flutter/material.dart';

import '../../models/delivery_model.dart';
import 'delivery_details.dart';
import 'executive_repository.dart';

class DeliveriesScreen extends StatefulWidget {
  final ExecutiveRepository repository;

  const DeliveriesScreen({super.key, required this.repository});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  List<DeliveryModel> _deliveries = const [];
  String _filter = 'ALL';
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.load();
      if (mounted) {
        setState(() => _deliveries = result.deliveries);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter == 'ALL'
        ? _deliveries
        : _deliveries.where((delivery) => delivery.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My deliveries')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _filter,
              decoration: const InputDecoration(labelText: 'Filter status'),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All statuses')),
                DropdownMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
                DropdownMenuItem(value: 'PICKED UP', child: Text('Picked up')),
                DropdownMenuItem(
                  value: 'OUT FOR DELIVERY',
                  child: Text('Out for delivery'),
                ),
                DropdownMenuItem(value: 'DELIVERED', child: Text('Delivered')),
                DropdownMenuItem(value: 'FAILED', child: Text('Failed')),
              ],
              onChanged: (value) => setState(() => _filter = value ?? 'ALL'),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) _Message(onRetry: _load),
            if (!_loading && _error == null && visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No deliveries match this filter.')),
              ),
            ...visible.map(
              (delivery) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  isThreeLine: true,
                  title: Text(
                    delivery.orderId.isEmpty
                        ? 'Order unavailable'
                        : delivery.orderId,
                  ),
                  subtitle: Text(
                    '${delivery.customerName}\n'
                    '${delivery.city}  |  ${delivery.status}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeliveryDetailsScreen(
                        delivery: delivery,
                        repository: widget.repository,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final VoidCallback onRetry;

  const _Message({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Deliveries could not be loaded.'),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
