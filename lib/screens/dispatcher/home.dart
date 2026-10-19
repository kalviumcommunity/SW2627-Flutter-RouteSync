import 'package:flutter/material.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/models/escalation_model.dart';
import 'package:routesync/models/user_model.dart';
import 'package:routesync/screens/dispatcher/deliveries.dart';
import 'package:routesync/screens/dispatcher/delivery_details.dart';
import 'package:routesync/screens/dispatcher/escalations.dart';
import 'package:routesync/screens/dispatcher/notifications.dart';
import 'package:routesync/screens/dispatcher/profile.dart';
import 'package:routesync/widgets/dashboard_card.dart';
import 'package:routesync/widgets/delivery_card.dart';

class DispatcherHome extends StatefulWidget {
  const DispatcherHome({super.key});

  @override
  State<DispatcherHome> createState() => _DispatcherHomeState();
}

class _DispatcherHomeState extends State<DispatcherHome> {
  var _selectedTab = 0;
  var _deliveriesScreenVersion = 0;
  var _initialDeliveryStatus = 'All statuses';

  final List<DeliveryModel> _deliveries = [
    DeliveryModel(
      id: 'delivery-1001',
      orderId: 'RS-10482',
      customerName: 'Aarav Shah',
      customerPhone: '+91 98765 43210',
      address: '14 Park Street',
      city: 'Bengaluru',
      assignedExecutiveId: 'EX-014',
      status: 'IN_TRANSIT',
      createdAt: DateTime(2026, 10, 17, 9),
      updatedAt: DateTime(2026, 10, 17, 12, 30),
    ),
    DeliveryModel(
      id: 'delivery-1002',
      orderId: 'RS-10483',
      customerName: 'Meera Iyer',
      customerPhone: '+91 98765 43211',
      address: '22 Lake View Road',
      city: 'Chennai',
      assignedExecutiveId: 'EX-008',
      status: 'OUT_FOR_DELIVERY',
      createdAt: DateTime(2026, 10, 17, 8, 15),
      updatedAt: DateTime(2026, 10, 17, 11, 45),
    ),
    DeliveryModel(
      id: 'delivery-1003',
      orderId: 'RS-10484',
      customerName: 'Rohan Patel',
      customerPhone: '+91 98765 43212',
      address: '8 Market Lane',
      city: 'Mumbai',
      assignedExecutiveId: 'EX-021',
      status: 'DELIVERED',
      createdAt: DateTime(2026, 10, 16, 10),
      updatedAt: DateTime(2026, 10, 16, 15, 20),
    ),
    DeliveryModel(
      id: 'delivery-1004',
      orderId: 'RS-10485',
      customerName: 'Ananya Rao',
      customerPhone: '+91 98765 43213',
      address: '5 Central Avenue',
      city: 'Bengaluru',
      assignedExecutiveId: 'EX-014',
      status: 'FAILED',
      failureReason: 'Customer was not available at the delivery address.',
      notes: 'Customer requested a follow-up attempt.',
      createdAt: DateTime(2026, 10, 17, 9, 20),
      updatedAt: DateTime(2026, 10, 17, 13, 10),
    ),
    DeliveryModel(
      id: 'delivery-1005',
      orderId: 'RS-10486',
      customerName: 'Kabir Nair',
      customerPhone: '+91 98765 43214',
      address: '31 Garden Road',
      city: 'Chennai',
      assignedExecutiveId: 'EX-008',
      status: 'ASSIGNED',
      createdAt: DateTime(2026, 10, 17, 13, 5),
    ),
    DeliveryModel(
      id: 'delivery-1006',
      orderId: 'RS-10487',
      customerName: 'Diya Kulkarni',
      customerPhone: '+91 98765 43215',
      address: '9 Riverside Walk',
      city: 'Mumbai',
      assignedExecutiveId: 'EX-021',
      status: 'IN_TRANSIT',
      createdAt: DateTime(2026, 10, 17, 10, 10),
      updatedAt: DateTime(2026, 10, 17, 13, 25),
    ),
  ];

  final List<EscalationModel> _escalations = [
    EscalationModel(
      id: 'escalation-501',
      deliveryId: 'delivery-1004',
      raisedBy: 'EX-014',
      reason: 'Customer unavailable',
      description: 'The customer could not be reached at the address. A second attempt is requested.',
      priority: 'HIGH',
      status: 'OPEN',
      createdAt: DateTime(2026, 10, 17, 13, 12),
    ),
    EscalationModel(
      id: 'escalation-502',
      deliveryId: 'delivery-1002',
      raisedBy: 'EX-008',
      reason: 'Address clarification',
      description: 'The building entrance is not clearly marked; customer confirmation is needed.',
      priority: 'MEDIUM',
      status: 'OPEN',
      createdAt: DateTime(2026, 10, 17, 12, 5),
    ),
  ];

  final _dispatcher = const UserModel(
    id: 'dispatcher-preview',
    name: 'RouteSync Dispatcher',
    email: 'dispatcher@routesync.local',
    role: 'Dispatcher',
    city: 'All cities',
  );

  List<EscalationModel> get _openEscalations => _escalations
      .where((item) => item.status.toUpperCase() == 'OPEN')
      .toList();

  int get _activeDeliveries => _deliveries.where((item) {
    final status = item.status.toUpperCase();
    return status != 'DELIVERED' && status != 'FAILED' && status != 'CANCELLED';
  }).length;

  int get _completedDeliveries => _deliveries
      .where((item) => item.status.toUpperCase() == 'DELIVERED')
      .length;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(context),
      DeliveriesScreen(
        key: ValueKey(_deliveriesScreenVersion),
        deliveries: _deliveries,
        initialStatusFilter: _initialDeliveryStatus,
      ),
      EscalationsScreen(
        escalations: _escalations,
        deliveries: _deliveries,
        onResolve: _resolveEscalation,
      ),
      const NotificationsScreen(),
      ProfileScreen(user: _dispatcher, onLogout: _showLogoutNotice),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _openEscalations.isNotEmpty,
              label: Text('${_openEscalations.length}'),
              child: const Icon(Icons.report_problem_outlined),
            ),
            selectedIcon: const Icon(Icons.report_problem),
            label: 'Issues',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final recentDeliveries = _deliveries.take(4).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RouteSync',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _selectedTab = 3),
            icon: Badge(
              isLabelVisible: _openEscalations.isNotEmpty,
              child: const Icon(Icons.notifications_none),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Dispatcher dashboard',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Here’s your delivery operations at a glance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preview data only. Live delivery, escalation, and account services are not connected.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              DashboardCard(
                label: 'Active deliveries',
                value: '$_activeDeliveries',
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF176B87),
                onTap: () => _showDeliveries('All statuses'),
              ),
              DashboardCard(
                label: 'Completed',
                value: '$_completedDeliveries',
                icon: Icons.task_alt,
                color: const Color(0xFF18794E),
                onTap: () => _showDeliveries('DELIVERED'),
              ),
              DashboardCard(
                label: 'Failed',
                value:
                    '${_deliveries.where((item) => item.status.toUpperCase() == 'FAILED').length}',
                icon: Icons.error_outline,
                color: const Color(0xFFB3261E),
                onTap: () => _showDeliveries('FAILED'),
              ),
              DashboardCard(
                label: 'Open escalations',
                value: '${_openEscalations.length}',
                icon: Icons.report_problem_outlined,
                color: const Color(0xFF8A5A00),
                onTap: () => setState(() => _selectedTab = 2),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent deliveries',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedTab = 1),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final delivery in recentDeliveries) ...[
            DeliveryCard(
              delivery: delivery,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      DeliveryDetailsScreen(delivery: delivery),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _showDeliveries(String status) {
    setState(() {
      _initialDeliveryStatus = status;
      _deliveriesScreenVersion++;
      _selectedTab = 1;
    });
  }

  void _resolveEscalation(String id) {
    setState(() {
      final index = _escalations.indexWhere((item) => item.id == id);
      if (index < 0) return;
      final escalation = _escalations[index];
      _escalations[index] = EscalationModel(
        id: escalation.id,
        deliveryId: escalation.deliveryId,
        raisedBy: escalation.raisedBy,
        reason: escalation.reason,
        description: escalation.description,
        priority: escalation.priority,
        status: 'RESOLVED',
        createdAt: escalation.createdAt,
        resolvedAt: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Escalation resolved in this preview session.'),
      ),
    );
  }

  void _showLogoutNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connect logout to the authentication service.'),
      ),
    );
  }
}
