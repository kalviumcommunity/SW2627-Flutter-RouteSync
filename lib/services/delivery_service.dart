import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/delivery_model.dart';
import '../utils/app_constants.dart';

class DeliveryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DeliveryService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _deliveries =>
      _firestore.collection('deliveries');

  Stream<List<DeliveryModel>> watchAll() {
    return _deliveries.snapshots().map(_mapSnapshot);
  }

  Stream<List<DeliveryModel>> watchAssignedTo(String executiveId) {
    return _deliveries
        .where('assignedExecutiveId', isEqualTo: executiveId)
        .snapshots()
        .map(_mapSnapshot);
  }

  Future<DeliveryModel?> getById(String deliveryId) async {
    final snapshot = await _deliveries.doc(deliveryId).get();
    final data = snapshot.data();
    return snapshot.exists && data != null
        ? DeliveryModel.fromMap(snapshot.id, data)
        : null;
  }

  Future<void> assignExecutive({
    required String deliveryId,
    required String executiveId,
  }) async {
    if (_auth.currentUser == null) {
      throw StateError('An authenticated dispatcher is required.');
    }
    await _deliveries.doc(deliveryId).update({
      'assignedExecutiveId': executiveId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProofImageUrl({
    required String deliveryId,
    required String proofImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'An authenticated user is required to update delivery proof.',
      );
    }

    final reference = _deliveries.doc(deliveryId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StateError('Delivery $deliveryId does not exist.');
      }
      if (data['assignedExecutiveId'] != user.uid) {
        throw StateError(
          'The authenticated user is not assigned to this delivery.',
        );
      }
      transaction.update(reference, {
        'proofImageUrl': proofImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<DeliveryModel> updateStatus({
    required String deliveryId,
    required String status,
    String? failureReason,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'An authenticated user is required to update a delivery.',
      );
    }

    final nextStatus = DeliveryStatuses.normalize(status);
    if (!DeliveryStatuses.values.contains(nextStatus)) {
      throw ArgumentError.value(
        status,
        'status',
        'Unsupported delivery status.',
      );
    }

    if (nextStatus == DeliveryStatuses.failed &&
        !failureReasons.contains(failureReason)) {
      throw ArgumentError.value(
        failureReason,
        'failureReason',
        'A valid failure reason is required.',
      );
    }

    final reference = _deliveries.doc(deliveryId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StateError('Delivery $deliveryId does not exist.');
      }

      final current = DeliveryModel.fromMap(snapshot.id, data);
      if (current.assignedExecutiveId != user.uid) {
        throw StateError(
          'The authenticated user is not assigned to this delivery.',
        );
      }
      if (!DeliveryStatuses.canTransition(current.status, nextStatus)) {
        throw StateError(
          'Cannot transition delivery from ${current.status} to $nextStatus.',
        );
      }

      transaction.update(reference, {
        'status': nextStatus,
        'failureReason': nextStatus == DeliveryStatuses.failed
            ? failureReason
            : null,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final updated = await getById(deliveryId);
    if (updated == null) {
      throw StateError('Delivery $deliveryId was not available after update.');
    }
    return updated;
  }

  List<DeliveryModel> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((document) => DeliveryModel.fromMap(document.id, document.data()))
        .toList(growable: false);
  }
}
