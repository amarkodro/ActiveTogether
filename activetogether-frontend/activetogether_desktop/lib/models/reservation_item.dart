import 'payment_info.dart';

class ReservationItem {
  final int id;
  final int activityId;
  final String activityName;
  final DateTime activityDateTime;
  final int userId;
  final String userName;
  final String? userProfileImageUrl;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final PaymentInfo? payment;

  ReservationItem({
    required this.id,
    required this.activityId,
    required this.activityName,
    required this.activityDateTime,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancellationReason,
    this.cancelledAt,
    this.payment,
  });

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      id: json['id'] as int,
      activityId: json['activityId'] as int,
      activityName: json['activityName'] as String,
      activityDateTime: DateTime.parse(json['activityDateTime'] as String),
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userProfileImageUrl: json['userProfileImageUrl'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      payment: json['payment'] != null
          ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }
}
