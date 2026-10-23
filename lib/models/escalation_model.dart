import 'firestore_value_converters.dart';
import '../utils/app_constants.dart';

class EscalationModel {
  final String id;
  final String deliveryId;
  final String raisedBy;
  final String reason;
  final String description;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const EscalationModel({
    required this.id,
    required this.deliveryId,
    required this.raisedBy,
    required this.reason,
    required this.description,
    this.priority = EscalationValues.medium,
    this.status = EscalationValues.open,
    this.createdAt,
    this.resolvedAt,
  });

  factory EscalationModel.fromMap(String id, Map<String, dynamic> data) {
    return EscalationModel(
      id: id,
      deliveryId: _stringValue(data['deliveryId']) ?? '',
      raisedBy: _stringValue(data['raisedBy']) ?? '',
      reason: _stringValue(data['reason']) ?? '',
      description: _stringValue(data['description']) ?? '',
      priority: EscalationValues.normalizePriority(
        _stringValue(data['priority']),
      ),
      status: EscalationValues.normalizeStatus(_stringValue(data['status'])),
      createdAt: dateTimeFromFirestore(data['createdAt']),
      resolvedAt: dateTimeFromFirestore(data['resolvedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryId': deliveryId,
      'raisedBy': raisedBy,
      'reason': reason,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': dateTimeToFirestore(createdAt),
      'resolvedAt': dateTimeToFirestore(resolvedAt),
    };
  }

  static String? _stringValue(Object? value) {
    return value is String ? value : null;
  }
}
