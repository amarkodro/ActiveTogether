class UserListItem {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final String? cityName;
  final String? profileImageUrl;
  final DateTime createdAt;

  UserListItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    this.cityName,
    this.profileImageUrl,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    return UserListItem(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      cityName: json['cityName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
