class ActivityFillRate {
  final String activityName;
  final int reservedCount;
  final int capacity;
  final double fillRatio;

  ActivityFillRate({
    required this.activityName,
    required this.reservedCount,
    required this.capacity,
    required this.fillRatio,
  });

  factory ActivityFillRate.fromJson(Map<String, dynamic> json) {
    return ActivityFillRate(
      activityName: json['activityName'] as String,
      reservedCount: json['reservedCount'] as int,
      capacity: json['capacity'] as int,
      fillRatio: (json['fillRatio'] as num).toDouble(),
    );
  }
}

class RecentReservationEntry {
  final String userName;
  final DateTime createdAt;
  final String status;

  RecentReservationEntry({
    required this.userName,
    required this.createdAt,
    required this.status,
  });

  factory RecentReservationEntry.fromJson(Map<String, dynamic> json) {
    return RecentReservationEntry(
      userName: json['userName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      status: json['status'] as String,
    );
  }
}

class OrganizerDashboardStats {
  final int activeActivitiesCount;
  final int newActivitiesThisWeek;
  final int totalParticipants;
  final int newParticipantsThisWeek;
  final double monthlyRevenue;
  final double averageRating;
  final List<ActivityFillRate> activityFillRates;
  final List<RecentReservationEntry> recentReservations;

  OrganizerDashboardStats({
    required this.activeActivitiesCount,
    required this.newActivitiesThisWeek,
    required this.totalParticipants,
    required this.newParticipantsThisWeek,
    required this.monthlyRevenue,
    required this.averageRating,
    required this.activityFillRates,
    required this.recentReservations,
  });

  factory OrganizerDashboardStats.fromJson(Map<String, dynamic> json) {
    return OrganizerDashboardStats(
      activeActivitiesCount: json['activeActivitiesCount'] as int,
      newActivitiesThisWeek: json['newActivitiesThisWeek'] as int,
      totalParticipants: json['totalParticipants'] as int,
      newParticipantsThisWeek: json['newParticipantsThisWeek'] as int,
      monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
      activityFillRates: (json['activityFillRates'] as List)
          .map((e) => ActivityFillRate.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentReservations: (json['recentReservations'] as List)
          .map(
            (e) => RecentReservationEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
