
class DeliveryModel {
  final String id;
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String address;
  final String city;
  final String assignedExecutiveId;
  final String status;
  final String? failureReason;
  final String? notes;
  final String? proofImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.city,
    required this.assignedExecutiveId,
    required this.status,
    this.failureReason,
    this.notes,
    this.proofImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return DeliveryModel(
      id: id,
      orderId: data['orderId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      assignedExecutiveId:
          data['assignedExecutiveId'] as String? ?? '',
      status: data['status'] as String? ?? 'ASSIGNED',
      failureReason: data['failureReason'] as String?,
      notes: data['notes'] as String?,
      proofImageUrl: data['proofImageUrl'] as String?,
      createdAt: (data['createdAt'] as DateTime?),
      updatedAt: (data['updatedAt'] as DateTime?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'city': city,
      'assignedExecutiveId': assignedExecutiveId,
      'status': status,
      'failureReason': failureReason,
      'notes': notes,
      'proofImageUrl': proofImageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
