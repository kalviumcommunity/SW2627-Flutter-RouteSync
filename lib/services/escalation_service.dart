import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/escalation_model.dart';
import '../utils/app_constants.dart';

class EscalationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EscalationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _escalations =>
      _firestore.collection('escalations');

  Stream<List<EscalationModel>> watchAll() {
    return _escalations.snapshots().map(_mapSnapshot);
  }

  Stream<List<EscalationModel>> watchForDelivery(String deliveryId) {
    return _escalations
        .where('deliveryId', isEqualTo: deliveryId)
        .snapshots()
        .map(_mapSnapshot);
  }

  Future<EscalationModel> create({
    required String deliveryId,
    required String reason,
    required String description,
    required String priority,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'An authenticated user is required to create an escalation.',
      );
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'A reason is required.');
    }
    final normalizedPriority = EscalationValues.normalizePriority(priority);
    if (!EscalationValues.priorities.contains(normalizedPriority)) {
      throw ArgumentError.value(priority, 'priority', 'Unsupported priority.');
    }

    final delivery = await _firestore
        .collection('deliveries')
        .doc(deliveryId)
        .get();
    final deliveryData = delivery.data();
    if (!delivery.exists ||
        deliveryData == null ||
        deliveryData['assignedExecutiveId'] != user.uid) {
      throw StateError(
        'The authenticated user is not assigned to this delivery.',
      );
    }

    final reference = await _escalations.add({
      'deliveryId': deliveryId,
      'raisedBy': user.uid,
      'reason': reason.trim(),
      'description': description.trim(),
      'priority': normalizedPriority,
      'status': EscalationValues.open,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Escalation was not available after creation.');
    }
    return EscalationModel.fromMap(snapshot.id, data);
  }

  Future<void> resolve(String escalationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'An authenticated user is required to resolve an escalation.',
      );
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    if (profile.data()?['role']?.toString().toUpperCase() !=
        UserRoles.dispatcher) {
      throw StateError('Only dispatchers can resolve escalations.');
    }

    await _escalations.doc(escalationId).update({
      'status': EscalationValues.resolved,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  List<EscalationModel> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => EscalationModel.fromMap(document.id, document.data()),
        )
        .toList(growable: false);
  }
}
