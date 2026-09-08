class Rating {
  final int id;
  final int reservationId;
  final int activityId;
  final int userId;
  final String userName;
  final String? userProfileImageUrl;
  final int score;
  final String? comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.reservationId,
    required this.activityId,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as int,
      reservationId: json['reservationId'] as int,
      activityId: json['activityId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      userProfileImageUrl: json['userProfileImageUrl'] as String?,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
