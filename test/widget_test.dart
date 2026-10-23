import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/models/escalation_model.dart';
import 'package:routesync/models/user_model.dart';
import 'package:routesync/main.dart';
import 'package:routesync/screens/executive/failed_delivery.dart';
import 'package:routesync/screens/executive/executive_repository.dart';
import 'package:routesync/screens/executive/raise_escalation.dart';
import 'package:routesync/screens/executive/update_status.dart';

void main() {
  testWidgets('RouteSync app displays its home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('RouteSync - Firebase Connected'), findsOneWidget);
  });

  testWidgets('Executive home shows operational summary', (tester) async {
    await tester.pumpWidget(const RouteSyncApp());
    await tester.pumpAndSettle();
    expect(find.text("Today's route"), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('Open my deliveries'), findsOneWidget);
  });

  testWidgets('dashboard navigates to assigned deliveries', (tester) async {
    await tester.pumpWidget(const RouteSyncApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open my deliveries'));
    await tester.pumpAndSettle();
    expect(find.text('My deliveries'), findsOneWidget);
    expect(find.text('No deliveries match this filter.'), findsOneWidget);
  });

  testWidgets('failed delivery requires a reason', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: FailedDeliveryScreen(
          delivery: _delivery('OUT FOR DELIVERY'),
          repository: repository,
        ),
      ),
    );
    await tester.tap(find.text('Save failed delivery'));
    await tester.pump();
    expect(find.text('Select a failure reason.'), findsOneWidget);
    expect(repository.statusUpdates, isEmpty);
  });

  testWidgets('escalation requires a short reason', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: RaiseEscalationScreen(
          delivery: _delivery('OUT FOR DELIVERY'),
          repository: repository,
        ),
      ),
    );
    await tester.tap(find.text('Submit escalation'));
    await tester.pump();
    expect(find.text('Enter a short reason.'), findsOneWidget);
    expect(repository.escalations, isEmpty);
  });

  testWidgets('status submission is disabled while persistence is pending', (
    tester,
  ) async {
    final repository = _FakeRepository()
      ..pendingStatus = Completer<DeliveryModel>();
    await tester.pumpWidget(
      MaterialApp(
        home: UpdateStatusScreen(
          delivery: _delivery('ASSIGNED'),
          repository: repository,
        ),
      ),
    );
    await tester.tap(find.text('Confirm update'));
    await tester.pump();
    await tester.tap(find.text('Confirm update'));
    expect(repository.statusUpdates, ['PICKED UP']);
    repository.pendingStatus!.complete(_delivery('PICKED UP'));
    await tester.pumpAndSettle();
  });

  test('status workflow only permits forward transitions', () {
    expect(canMoveTo('ASSIGNED', 'PICKED UP'), isTrue);
    expect(canMoveTo('PICKED UP', 'OUT FOR DELIVERY'), isTrue);
    expect(canMoveTo('OUT FOR DELIVERY', 'DELIVERED'), isTrue);
    expect(canMoveTo('OUT FOR DELIVERY', 'FAILED'), isTrue);
    expect(canMoveTo('DELIVERED', 'ASSIGNED'), isFalse);
    expect(canMoveTo('ASSIGNED', 'DELIVERED'), isFalse);
  });

  test('failure reasons and escalation priorities match the contract', () {
    expect(failureReasons, <String>[
      'Customer unavailable',
      'Incorrect address',
      'Customer refused delivery',
      'Vehicle issue',
      'Delivery area inaccessible',
      'Other',
    ]);
    expect(escalationPriorities, <String>['LOW', 'MEDIUM', 'HIGH']);
  });

  test('unconfigured persistence never reports a successful write', () async {
    const repository = UnavailableExecutiveRepository();
    await expectLater(
      repository.createEscalation(
        deliveryId: 'delivery-1',
        reason: 'Test',
        description: '',
        priority: 'HIGH',
      ),
      throwsUnsupportedError,
    );
  });
}

DeliveryModel _delivery(String status) => DeliveryModel(
  id: 'delivery-1',
  orderId: 'RS-001',
  customerName: 'A Customer',
  customerPhone: '000',
  address: '1 Route Street',
  city: 'Leeds',
  assignedExecutiveId: 'executive-1',
  status: status,
);

class _FakeRepository implements ExecutiveRepository {
  final statusUpdates = <String>[];
  final escalations = <String>[];
  Completer<DeliveryModel>? pendingStatus;

  @override
  Future<ExecutiveSnapshot> load() async => const ExecutiveSnapshot(
    user: UserModel(
      id: 'executive-1',
      name: 'Executive',
      email: 'executive@example.com',
      role: 'executive',
      city: 'Leeds',
    ),
    deliveries: <DeliveryModel>[],
  );

  @override
  Future<DeliveryModel> updateStatus(
    DeliveryModel delivery,
    String status, {
    String? failureReason,
    String? notes,
  }) {
    statusUpdates.add(status);
    return pendingStatus?.future ?? Future.value(_delivery(status));
  }

  @override
  Future<EscalationModel> createEscalation({
    required String deliveryId,
    required String reason,
    required String description,
    required String priority,
  }) {
    escalations.add(reason);
    return Future.value(
      EscalationModel(
        id: 'escalation-1',
        deliveryId: deliveryId,
        raisedBy: 'executive-1',
        reason: reason,
        description: description,
        priority: priority,
      ),
    );
  }

  @override
  Future<String> uploadProof(DeliveryModel delivery) =>
      Future.value('https://example.com/proof.jpg');

  @override
  Future<void> signOut() async {}
}
