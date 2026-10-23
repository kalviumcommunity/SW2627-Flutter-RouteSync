import 'package:flutter/material.dart';

import '../../models/delivery_model.dart';
import '../../models/escalation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../services/escalation_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/dashboard_card.dart';
import 'deliveries.dart';
import 'escalations.dart';
import 'notifications.dart';
import 'profile.dart';

class FirebaseDispatcherHome extends StatefulWidget {
  final AuthService authService;
  final DeliveryService deliveryService;
  final EscalationService escalationService;

  const FirebaseDispatcherHome({
    super.key,
    required this.authService,
    required this.deliveryService,
    required this.escalationService,
  });

  @override
  State<FirebaseDispatcherHome> createState() => _FirebaseDispatcherHomeState();
}

class _FirebaseDispatcherHomeState extends State<FirebaseDispatcherHome> {
  late final Future<UserModel?> _profile;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.authService.getCurrentUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _profile,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profileSnapshot.hasError || profileSnapshot.data == null) {
          return _DispatcherError(
            message: profileSnapshot.hasError
                ? profileSnapshot.error.toString()
                : 'Dispatcher profile is unavailable.',
            onSignOut: widget.authService.signOut,
          );
        }
        return StreamBuilder<List<DeliveryModel>>(
          stream: widget.deliveryService.watchAll(),
          builder: (context, deliverySnapshot) {
            return StreamBuilder<List<EscalationModel>>(
              stream: widget.escalationService.watchAll(),
              builder: (context, escalationSnapshot) {
                return _DispatcherScaffold(
                  user: profileSnapshot.data!,
                  deliveries: deliverySnapshot.data ?? const [],
                  escalations: escalationSnapshot.data ?? const [],
                  selectedTab: _selectedTab,
                  onTabChanged: (value) => setState(() => _selectedTab = value),
                  onResolve: (id) => _resolveEscalation(id),
                  onSignOut: widget.authService.signOut,
                  authService: widget.authService,
                  deliveryService: widget.deliveryService,
                  loading:
                      deliverySnapshot.connectionState ==
                          ConnectionState.waiting ||
                      escalationSnapshot.connectionState ==
                          ConnectionState.waiting,
                  error: deliverySnapshot.error ?? escalationSnapshot.error,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _resolveEscalation(String id) async {
    try {
      await widget.escalationService.resolve(id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resolve escalation: $error')),
        );
      }
    }
  }
}

class _DispatcherScaffold extends StatelessWidget {
  final UserModel user;
  final List<DeliveryModel> deliveries;
  final List<EscalationModel> escalations;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onResolve;
  final Future<void> Function() onSignOut;
  final AuthService authService;
  final DeliveryService deliveryService;
  final bool loading;
  final Object? error;

  const _DispatcherScaffold({
    required this.user,
    required this.deliveries,
    required this.escalations,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onResolve,
    required this.onSignOut,
    required this.authService,
    required this.deliveryService,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
        deliveries: deliveries,
        escalations: escalations,
        loading: loading,
        error: error,
        onTabChanged: onTabChanged,
      ),
      DeliveriesScreen(
        deliveries: deliveries,
        executiveStream: authService.watchActiveExecutives(),
        onAssign: deliveryService.assignExecutive,
      ),
      EscalationsScreen(
        escalations: escalations,
        deliveries: deliveries,
        onResolve: onResolve,
      ),
      const NotificationsScreen(),
      ProfileScreen(
        user: user,
        onLogout: () {
          onSignOut();
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[selectedTab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: onTabChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning),
            label: 'Escalations',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final List<DeliveryModel> deliveries;
  final List<EscalationModel> escalations;
  final bool loading;
  final Object? error;
  final ValueChanged<int> onTabChanged;

  const _Dashboard({
    required this.deliveries,
    required this.escalations,
    required this.loading,
    required this.error,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = deliveries.where(
      (delivery) =>
          delivery.status != DeliveryStatuses.delivered &&
          delivery.status != DeliveryStatuses.failed,
    );
    final openEscalations = escalations
        .where((item) => item.status == EscalationValues.open)
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Dispatcher desk',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text('Live delivery operations overview.'),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Some live data could not be loaded: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DashboardCard(
              label: 'Active deliveries',
              value: '${active.length}',
              icon: Icons.local_shipping_outlined,
              color: Colors.blue,
              onTap: () => onTabChanged(1),
            ),
            DashboardCard(
              label: 'Delivered',
              value:
                  '${deliveries.where((delivery) => delivery.status == DeliveryStatuses.delivered).length}',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () => onTabChanged(1),
            ),
            DashboardCard(
              label: 'Failed',
              value:
                  '${deliveries.where((delivery) => delivery.status == DeliveryStatuses.failed).length}',
              icon: Icons.error_outline,
              color: Colors.red,
              onTap: () => onTabChanged(1),
            ),
            DashboardCard(
              label: 'Open escalations',
              value: '$openEscalations',
              icon: Icons.warning_amber_outlined,
              color: Colors.orange,
              onTap: () => onTabChanged(2),
            ),
          ],
        ),
      ],
    );
  }
}

class _DispatcherError extends StatelessWidget {
  final String message;
  final Future<void> Function() onSignOut;

  const _DispatcherError({required this.message, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
