import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateTimeFromFirestore(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

Object? dateTimeToFirestore(DateTime? value) {
  return value == null ? null : Timestamp.fromDate(value);
}
