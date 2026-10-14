
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
    this.priority = 'MEDIUM',
    this.status = 'OPEN',
    this.createdAt,
    this.resolvedAt,
  });

  factory EscalationModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return EscalationModel(
      id: id,
      deliveryId: data['deliveryId'] as String? ?? '',
      raisedBy: data['raisedBy'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String? ?? '',
      priority: data['priority'] as String? ?? 'MEDIUM',
      status: data['status'] as String? ?? 'OPEN',
      createdAt: data['createdAt'] as DateTime?,
      resolvedAt: data['resolvedAt'] as DateTime?,
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
      'createdAt': createdAt,
      'resolvedAt': resolvedAt,
    };
  }
}
