class PaymentInfo {
  final int id;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  PaymentInfo({
    required this.id,
    required this.amount,
    required this.status,
    this.paidAt,
    this.refundedAt,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'] as String)
          : null,
    );
  }
}
