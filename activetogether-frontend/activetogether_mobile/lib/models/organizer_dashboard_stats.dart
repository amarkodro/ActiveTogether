class OrganizerDashboardStats {
  final int activeActivitiesCount;
  final int totalParticipants;
  final double averageRating;

  OrganizerDashboardStats({
    required this.activeActivitiesCount,
    required this.totalParticipants,
    required this.averageRating,
  });

  factory OrganizerDashboardStats.fromJson(Map<String, dynamic> json) {
    return OrganizerDashboardStats(
      activeActivitiesCount: json['activeActivitiesCount'] as int? ?? 0,
      totalParticipants: json['totalParticipants'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }
}
