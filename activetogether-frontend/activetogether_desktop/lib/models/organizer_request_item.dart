class OrganizerRequestItem {
  final int id;
  final int userId;
  final String userFullName;
  final String userEmail;
  final String? userProfileImageUrl;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? decidedAt;

  OrganizerRequestItem({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    this.userProfileImageUrl,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.decidedAt,
  });

  String get initials {
    final parts = userFullName.trim().split(' ');
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$last'.toUpperCase();
  }

  factory OrganizerRequestItem.fromJson(Map<String, dynamic> json) {
    return OrganizerRequestItem(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      userEmail: json['userEmail'] as String,
      userProfileImageUrl: json['userProfileImageUrl'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      decidedAt: json['decidedAt'] != null
          ? DateTime.parse(json['decidedAt'] as String)
          : null,
    );
  }
}
