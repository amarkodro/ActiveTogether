class AppUser {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;
  final String? profileImageUrl;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
}
