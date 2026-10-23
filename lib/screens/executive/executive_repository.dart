import 'dart:typed_data';

import '../../models/delivery_model.dart';
import '../../models/escalation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../services/escalation_service.dart';
import '../../services/storage_service.dart';

abstract class ExecutiveRepository {
  Future<ExecutiveSnapshot> load();
  Future<DeliveryModel> updateStatus(
    DeliveryModel delivery,
    String status, {
    String? failureReason,
    String? notes,
  });
  Future<EscalationModel> createEscalation({
    required String deliveryId,
    required String reason,
    required String description,
    required String priority,
  });
  Future<String> uploadProof(DeliveryModel delivery);
  Future<void> signOut();
}

abstract class ExecutiveRealtimeRepository implements ExecutiveRepository {
  Stream<ExecutiveSnapshot> watch();
}

class ExecutiveSnapshot {
  final UserModel? user;
  final List<DeliveryModel> deliveries;
  final bool notificationsSupported;
  const ExecutiveSnapshot({
    required this.user,
    required this.deliveries,
    this.notificationsSupported = false,
  });
}

class UnavailableExecutiveRepository implements ExecutiveRepository {
  const UnavailableExecutiveRepository();
  @override
  Future<ExecutiveSnapshot> load() async =>
      const ExecutiveSnapshot(user: null, deliveries: <DeliveryModel>[]);
  @override
  Future<DeliveryModel> updateStatus(
    DeliveryModel delivery,
    String status, {
    String? failureReason,
    String? notes,
  }) => Future.error(
    UnsupportedError('Firebase delivery service is not configured.'),
  );
  @override
  Future<EscalationModel> createEscalation({
    required String deliveryId,
    required String reason,
    required String description,
    required String priority,
  }) => Future.error(
    UnsupportedError('Firebase escalation service is not configured.'),
  );
  @override
  Future<String> uploadProof(DeliveryModel delivery) => Future.error(
    UnsupportedError('Firebase Storage service is not configured.'),
  );
  @override
  Future<void> signOut() async {}
}

class FirebaseExecutiveRepository implements ExecutiveRealtimeRepository {
  final AuthService authService;
  final DeliveryService deliveryService;
  final EscalationService escalationService;
  final StorageService storageService;

  FirebaseExecutiveRepository({
    AuthService? authService,
    DeliveryService? deliveryService,
    EscalationService? escalationService,
    StorageService? storageService,
  }) : authService = authService ?? AuthService(),
       deliveryService = deliveryService ?? DeliveryService(),
       escalationService = escalationService ?? EscalationService(),
       storageService = storageService ?? StorageService();

  @override
  Future<ExecutiveSnapshot> load() async {
    final user = await authService.requireCurrentUserProfile();
    final deliveries = await deliveryService.watchAssignedTo(user.id).first;
    return ExecutiveSnapshot(user: user, deliveries: deliveries);
  }

  @override
  Stream<ExecutiveSnapshot> watch() async* {
    final user = await authService.requireCurrentUserProfile();
    await for (final deliveries in deliveryService.watchAssignedTo(user.id)) {
      yield ExecutiveSnapshot(user: user, deliveries: deliveries);
    }
  }

  @override
  Future<DeliveryModel> updateStatus(
    DeliveryModel delivery,
    String status, {
    String? failureReason,
    String? notes,
  }) {
    return deliveryService.updateStatus(
      deliveryId: delivery.id,
      status: status,
      failureReason: failureReason,
      notes: notes,
    );
  }

  @override
  Future<EscalationModel> createEscalation({
    required String deliveryId,
    required String reason,
    required String description,
    required String priority,
  }) {
    return escalationService.create(
      deliveryId: deliveryId,
      reason: reason,
      description: description,
      priority: priority,
    );
  }

  @override
  Future<String> uploadProof(DeliveryModel delivery) {
    return Future.error(
      UnsupportedError('Image selection is not configured for proof upload.'),
    );
  }

  Future<String> uploadProofBytes({
    required DeliveryModel delivery,
    required Uint8List bytes,
    required String contentType,
    String extension = 'jpg',
  }) async {
    final url = await storageService.uploadProofBytes(
      deliveryId: delivery.id,
      bytes: bytes,
      contentType: contentType,
      extension: extension,
    );
    await deliveryService.updateProofImageUrl(
      deliveryId: delivery.id,
      proofImageUrl: url,
    );
    return url;
  }

  @override
  Future<void> signOut() => authService.signOut();
}

bool canMoveTo(String current, String next) {
  if (current == 'ASSIGNED') {
    return next == 'PICKED UP';
  }
  if (current == 'PICKED UP') {
    return next == 'OUT FOR DELIVERY';
  }
  if (current == 'OUT FOR DELIVERY') {
    return next == 'DELIVERED' || next == 'FAILED';
  }
  return false;
}

const failureReasons = <String>[
  'Customer unavailable',
  'Incorrect address',
  'Customer refused delivery',
  'Vehicle issue',
  'Delivery area inaccessible',
  'Other',
];

const escalationPriorities = <String>['LOW', 'MEDIUM', 'HIGH'];
