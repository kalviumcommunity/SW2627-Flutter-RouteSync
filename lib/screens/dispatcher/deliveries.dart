import 'package:flutter/material.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/models/user_model.dart';
import 'package:routesync/screens/dispatcher/delivery_details.dart';
import 'package:routesync/widgets/delivery_card.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({
    super.key,
    required this.deliveries,
    this.initialStatusFilter = 'All statuses',
    this.isLoading = false,
    this.errorMessage,
    this.executiveStream,
    this.onAssign,
  });

  final List<DeliveryModel> deliveries;
  final String initialStatusFilter;
  final bool isLoading;
  final String? errorMessage;
  final Stream<List<UserModel>>? executiveStream;
  final Future<void> Function({
    required String deliveryId,
    required String executiveId,
  })?
  onAssign;

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  final _searchController = TextEditingController();
  late String _status;
  String _city = 'All cities';
  String _executive = 'All executives';

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatusFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _options(widget.deliveries.map((item) => item.status));
    final cities = _options(widget.deliveries.map((item) => item.city));
    final executives = _options(
      widget.deliveries.map((item) => item.assignedExecutiveId),
    );
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.deliveries.where((delivery) {
      final matchesQuery =
          query.isEmpty ||
          delivery.orderId.toLowerCase().contains(query) ||
          delivery.customerName.toLowerCase().contains(query);
      return matchesQuery &&
          (_status == 'All statuses' || delivery.status == _status) &&
          (_city == 'All cities' || delivery.city == _city) &&
          (_executive == 'All executives' ||
              delivery.assignedExecutiveId == _executive);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            tooltip: 'Clear filters',
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search order or customer',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE8EDF0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE8EDF0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          value: _status,
                          options: ['All statuses', ...statuses],
                          label: 'Status',
                          onChanged: (value) => setState(() => _status = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterDropdown(
                          value: _city,
                          options: ['All cities', ...cities],
                          label: 'City',
                          onChanged: (value) => setState(() => _city = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _FilterDropdown(
                    value: _executive,
                    options: ['All executives', ...executives],
                    label: 'Executive',
                    onChanged: (value) => setState(() => _executive = value),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildResults(context, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<DeliveryModel> filtered) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.errorMessage case final message?) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load deliveries',
        message: message,
      );
    }
    if (filtered.isEmpty) {
      return _StateMessage(
        icon: Icons.inventory_2_outlined,
        title: widget.deliveries.isEmpty
            ? 'No deliveries yet'
            : 'No matching deliveries',
        message: widget.deliveries.isEmpty
            ? 'New deliveries will appear here when they are available.'
            : 'Try changing your search or filters.',
      );
    }
    Widget buildList(List<UserModel> executives) => ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final delivery = filtered[index];
        return DeliveryCard(
          delivery: delivery,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => DeliveryDetailsScreen(
                delivery: delivery,
                executives: executives,
                onAssign: widget.onAssign,
              ),
            ),
          ),
        );
      },
    );
    if (widget.executiveStream == null) return buildList(const []);
    return StreamBuilder<List<UserModel>>(
      stream: widget.executiveStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load executives',
            message: snapshot.error.toString(),
          );
        }
        return buildList(snapshot.data ?? const []);
      },
    );
  }

  List<String> _options(Iterable<String> values) {
    final uniqueValues =
        values.where((value) => value.trim().isNotEmpty).toSet().toList()
          ..sort();
    return uniqueValues;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _status = 'All statuses';
      _city = 'All cities';
      _executive = 'All executives';
    });
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8EDF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8EDF0)),
        ),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
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
            Icon(
              icon,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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
