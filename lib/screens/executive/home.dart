import 'package:flutter/material.dart';
import '../../models/delivery_model.dart';
import '../../widgets/delivery_action_button.dart';
import 'deliveries.dart';
import 'executive_repository.dart';
import 'notifications.dart';
import 'profile.dart';

class ExecutiveHome extends StatefulWidget {
  final ExecutiveRepository repository;
  const ExecutiveHome({super.key, this.repository = const UnavailableExecutiveRepository()});
  @override
  State<ExecutiveHome> createState() => _ExecutiveHomeState();
}

class _ExecutiveHomeState extends State<ExecutiveHome> {
  ExecutiveSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { if (mounted) setState(() => _snapshot = await widget.repository.load()); }
    catch (error) { if (mounted) setState(() => _error = error); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final deliveries = _snapshot?.deliveries ?? const <DeliveryModel>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Executive desk'), actions: [
        IconButton(tooltip: 'Notifications', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(snapshot: _snapshot))), icon: const Icon(Icons.notifications_none)),
        IconButton(tooltip: 'Profile', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(snapshot: _snapshot, onSignOut: widget.repository.signOut))), icon: const Icon(Icons.account_circle_outlined)),
      ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text("Today's route", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(_snapshot?.user?.name.isNotEmpty == true ? 'Welcome back, ${_snapshot!.user!.name}.' : 'Your assigned work, in one place.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) _ErrorState(onRetry: _load),
          _SummaryGrid(deliveries: deliveries),
          const SizedBox(height: 24),
          DeliveryActionButton(label: 'Open my deliveries', icon: Icons.route, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveriesScreen(repository: widget.repository)))),
          if (!_loading && _snapshot?.user == null) const Padding(padding: EdgeInsets.only(top: 20), child: _IntegrationNotice()),
        ]),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<DeliveryModel> deliveries;
  const _SummaryGrid({required this.deliveries});
  @override
  Widget build(BuildContext context) {
    final counts = {'Assigned': deliveries.where((d) => d.status == 'ASSIGNED').length, 'In progress': deliveries.where((d) => d.status == 'PICKED UP' || d.status == 'OUT FOR DELIVERY').length, 'Completed': deliveries.where((d) => d.status == 'DELIVERED').length, 'Failed': deliveries.where((d) => d.status == 'FAILED').length};
    return GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.65, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: counts.entries.map((entry) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.key), const Spacer(), Text('${entry.value}', style: Theme.of(context).textTheme.headlineMedium)])))).toList());
  }
}
class _IntegrationNotice extends StatelessWidget { const _IntegrationNotice(); @override Widget build(BuildContext context) => Card(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Padding(padding: EdgeInsets.all(16), child: Text('Delivery data is unavailable until the Firebase services are connected.'))); }
class _ErrorState extends StatelessWidget { final VoidCallback onRetry; const _ErrorState({required this.onRetry}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(children: [const Text('We could not load your route.'), TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'))])); }