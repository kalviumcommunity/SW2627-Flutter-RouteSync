import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routesync/models/delivery_model.dart';
import 'package:routesync/models/escalation_model.dart';
import 'package:routesync/models/firestore_value_converters.dart';
import 'package:routesync/models/user_model.dart';
import 'package:routesync/utils/app_constants.dart';

void main() {
  group('Firestore value conversion', () {
    test('converts Timestamp to DateTime', () {
      final value = DateTime.utc(2026, 10, 19, 8, 30);

      expect(
        dateTimeFromFirestore(Timestamp.fromDate(value))!
            .isAtSameMomentAs(value),
        isTrue,
      );
    });

    test('preserves DateTime values for test and local serialization', () {
      final value = DateTime.utc(2026, 10, 19, 8, 30);

      expect(dateTimeFromFirestore(value), value);
      expect(dateTimeToFirestore(value), Timestamp.fromDate(value));
    });

    test('returns null for unsupported timestamp values', () {
      expect(dateTimeFromFirestore('not-a-date'), isNull);
      expect(dateTimeToFirestore(null), isNull);
    });
  });

  group('DeliveryModel', () {
    test('normalizes supported statuses and Firestore timestamps', () {
      final createdAt = DateTime.utc(2026, 10, 19);
      final delivery = DeliveryModel.fromMap('delivery-1', {
        'status': 'out_for_delivery',
        'createdAt': Timestamp.fromDate(createdAt),
      });

      expect(delivery.status, DeliveryStatuses.outForDelivery);
      expect(delivery.createdAt!.isAtSameMomentAs(createdAt), isTrue);
      expect(delivery.toMap()['createdAt'], Timestamp.fromDate(createdAt));
    });

    test('preserves unknown and malformed statuses without assigning them', () {
      final delivery = DeliveryModel.fromMap('delivery-1', {
        'status': 'returned_to_sender',
        'customerName': 42,
        'createdAt': 42,
      });

      expect(delivery.status, 'RETURNED TO SENDER');
      expect(delivery.customerName, '');
      expect(delivery.createdAt, isNull);
    });

    test('uses an explicit invalid status for missing or malformed values', () {
      expect(
        DeliveryModel.fromMap('delivery-1', {}).status,
        DeliveryStatuses.invalid,
      );
      expect(
        DeliveryModel.fromMap('delivery-1', {'status': 42}).status,
        DeliveryStatuses.invalid,
      );
    });

    test('preserves a proof image URL through Firestore serialization', () {
      final delivery = DeliveryModel.fromMap('delivery-1', {
        'status': 'DELIVERED',
        'proofImageUrl': 'https://storage.example/proof.jpg',
      });

      expect(delivery.proofImageUrl, 'https://storage.example/proof.jpg');
      expect(
        DeliveryModel.fromMap('delivery-1', delivery.toMap()).proofImageUrl,
        delivery.proofImageUrl,
      );
    });
  });

  group('EscalationModel', () {
    test('normalizes priority and status', () {
      final escalation = EscalationModel.fromMap('escalation-1', {
        'priority': 'high',
        'status': 'resolved',
      });

      expect(escalation.priority, EscalationValues.high);
      expect(escalation.status, EscalationValues.resolved);
    });

    test('uses explicit invalid values for missing or malformed fields', () {
      final escalation = EscalationModel.fromMap('escalation-1', {
        'priority': 42,
        'status': 42,
      });

      expect(escalation.priority, EscalationValues.invalid);
      expect(escalation.status, EscalationValues.invalid);
      final missing = EscalationModel.fromMap('escalation-2', {});
      expect(missing.priority, EscalationValues.invalid);
      expect(missing.status, EscalationValues.invalid);
    });
  });

  group('UserModel', () {
    test('normalizes supported roles case-insensitively', () {
      final user = UserModel.fromMap('user-1', {'role': 'dispatcher'});

      expect(user.role, UserRoles.dispatcher);
    });

    test('uses an explicit invalid role for unsupported or missing values', () {
      expect(
        UserModel.fromMap('user-1', {'role': 'admin'}).role,
        UserRoles.invalid,
      );
      expect(UserModel.fromMap('user-1', {'role': 42}).role, UserRoles.invalid);
      expect(UserModel.fromMap('user-1', {}).role, UserRoles.invalid);
    });

    test('preserves supported legacy lowercase role values', () {
      expect(
        UserModel.fromMap('user-1', {'role': 'executive'}).role,
        UserRoles.executive,
      );
      expect(
        UserModel.fromMap('user-1', {'role': 'delivery executive'}).role,
        UserRoles.executive,
      );
    });
  });
}
