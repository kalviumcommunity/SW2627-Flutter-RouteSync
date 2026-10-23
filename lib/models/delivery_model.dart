import 'firestore_value_converters.dart';
import '../utils/app_constants.dart';

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

  factory DeliveryModel.fromMap(String id, Map<String, dynamic> data) {
    return DeliveryModel(
      id: id,
      orderId: _stringValue(data['orderId']) ?? '',
      customerName: _stringValue(data['customerName']) ?? '',
      customerPhone: _stringValue(data['customerPhone']) ?? '',
      address: _stringValue(data['address']) ?? '',
      city: _stringValue(data['city']) ?? '',
      assignedExecutiveId: _stringValue(data['assignedExecutiveId']) ?? '',
      status: DeliveryStatuses.normalize(_stringValue(data['status'])),
      failureReason: _stringValue(data['failureReason']),
      notes: _stringValue(data['notes']),
      proofImageUrl: _stringValue(data['proofImageUrl']),
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
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
      'createdAt': dateTimeToFirestore(createdAt),
      'updatedAt': dateTimeToFirestore(updatedAt),
    };
  }

  static String? _stringValue(Object? value) {
    return value is String ? value : null;
  }
}
