import '../../models/delivery_model.dart';
import '../../models/escalation_model.dart';
import '../../models/user_model.dart';

abstract class ExecutiveRepository {
  Future<ExecutiveSnapshot> load();
  Future<DeliveryModel> updateStatus(DeliveryModel delivery, String status, {String? failureReason, String? notes});
  Future<EscalationModel> createEscalation({required String deliveryId, required String reason, required String description, required String priority});
  Future<String> uploadProof(DeliveryModel delivery);
  Future<void> signOut();
}

class ExecutiveSnapshot {
  final UserModel? user;
  final List<DeliveryModel> deliveries;
  final bool notificationsSupported;
  const ExecutiveSnapshot({required this.user, required this.deliveries, this.notificationsSupported = false});
}

class UnavailableExecutiveRepository implements ExecutiveRepository {
  const UnavailableExecutiveRepository();
  @override
  Future<ExecutiveSnapshot> load() async => const ExecutiveSnapshot(user: null, deliveries: <DeliveryModel>[]);
  @override
  Future<DeliveryModel> updateStatus(DeliveryModel delivery, String status, {String? failureReason, String? notes}) => Future.error(const UnsupportedError('Firebase delivery service is not configured.'));
  @override
  Future<EscalationModel> createEscalation({required String deliveryId, required String reason, required String description, required String priority}) => Future.error(const UnsupportedError('Firebase escalation service is not configured.'));
  @override
  Future<String> uploadProof(DeliveryModel delivery) => Future.error(const UnsupportedError('Firebase Storage service is not configured.'));
  @override
  Future<void> signOut() async {}
}

bool canMoveTo(String current, String next) {
  if (current == 'ASSIGNED') return next == 'PICKED UP';
  if (current == 'PICKED UP') return next == 'OUT FOR DELIVERY';
  if (current == 'OUT FOR DELIVERY') return next == 'DELIVERED' || next == 'FAILED';
  return false;
}

const failureReasons = <String>['Customer unavailable', 'Incorrect address', 'Customer refused delivery', 'Vehicle issue', 'Delivery area inaccessible', 'Other'];

const escalationPriorities = <String>['LOW', 'MEDIUM', 'HIGH'];