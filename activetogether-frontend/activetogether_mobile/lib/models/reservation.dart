class ReservationPayment {
  final int id;
  final double amount;
  final String status;
  final String? clientSecret;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  ReservationPayment({
    required this.id,
    required this.amount,
    required this.status,
    this.clientSecret,
    this.paidAt,
    this.refundedAt,
  });

  factory ReservationPayment.fromJson(Map<String, dynamic> json) {
    return ReservationPayment(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      clientSecret: json['clientSecret'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String).toLocal()
          : null,
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'] as String).toLocal()
          : null,
    );
  }
}

class Reservation {
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
  final ReservationPayment? payment;
  final bool hasRating;

  Reservation({
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
    this.hasRating = false,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      activityId: json['activityId'] as int,
      activityName: json['activityName'] as String? ?? '',
      activityDateTime: DateTime.parse(
        json['activityDateTime'] as String,
      ).toLocal(),
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      userProfileImageUrl: json['userProfileImageUrl'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String).toLocal()
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String).toLocal()
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String).toLocal()
          : null,
      payment: json['payment'] != null
          ? ReservationPayment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      hasRating: json['hasRating'] as bool? ?? false,
    );
  }
}
