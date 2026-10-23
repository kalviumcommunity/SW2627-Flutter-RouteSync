import '../utils/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String city;
  final bool active;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.city,
    this.active = true,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: _stringValue(data['name']) ?? '',
      email: _stringValue(data['email']) ?? '',
      role: UserRoles.normalize(_stringValue(data['role'])),
      city: _stringValue(data['city']) ?? '',
      active: data['active'] is bool ? data['active'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'city': city,
      'active': active,
    };
  }

  static String? _stringValue(Object? value) {
    return value is String ? value : null;
  }
}
