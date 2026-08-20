class Profile {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String role;
  final int? cityId;
  final String? cityName;
  final String? profileImageUrl;
  final int totalReservations;
  final int completedActivitiesCount;
  final double? averageRatingGiven;

  Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.cityId,
    this.cityName,
    this.profileImageUrl,
    required this.totalReservations,
    required this.completedActivitiesCount,
    this.averageRatingGiven,
  });

  String get fullName => '$firstName $lastName';
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String? ?? '',
      cityId: json['cityId'] as int?,
      cityName: json['cityName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      totalReservations: json['totalReservations'] as int? ?? 0,
      completedActivitiesCount: json['completedActivitiesCount'] as int? ?? 0,
      averageRatingGiven: (json['averageRatingGiven'] as num?)?.toDouble(),
    );
  }
}
