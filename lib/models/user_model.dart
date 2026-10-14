
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
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'executive',
      city: data['city'] as String? ?? '',
      active: data['active'] as bool? ?? true,
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
}
