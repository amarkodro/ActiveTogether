class CategoryPopularity {
  final String categoryName;
  final int count;

  CategoryPopularity({required this.categoryName, required this.count});

  factory CategoryPopularity.fromJson(Map<String, dynamic> json) {
    return CategoryPopularity(
      categoryName: json['categoryName'] as String,
      count: json['count'] as int,
    );
  }
}

class RecentActivity {
  final int id;
  final String name;
  final String organizerName;
  final String status;

  RecentActivity({
    required this.id,
    required this.name,
    required this.organizerName,
    required this.status,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as int,
      name: json['name'] as String,
      organizerName: json['organizerName'] as String,
      status: json['status'] as String,
    );
  }
}

class AdminDashboardStats {
  final int totalUsers;
  final double usersGrowthPercent;
  final int totalActivities;
  final double activitiesGrowthPercent;
  final int totalReservations;
  final double reservationsGrowthPercent;
  final double totalRevenue;
  final double revenueGrowthPercent;
  final List<CategoryPopularity> categoryPopularity;
  final List<RecentActivity> recentActivities;

  AdminDashboardStats({
    required this.totalUsers,
    required this.usersGrowthPercent,
    required this.totalActivities,
    required this.activitiesGrowthPercent,
    required this.totalReservations,
    required this.reservationsGrowthPercent,
    required this.totalRevenue,
    required this.revenueGrowthPercent,
    required this.categoryPopularity,
    required this.recentActivities,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalUsers: json['totalUsers'] as int,
      usersGrowthPercent: (json['usersGrowthPercent'] as num).toDouble(),
      totalActivities: json['totalActivities'] as int,
      activitiesGrowthPercent: (json['activitiesGrowthPercent'] as num)
          .toDouble(),
      totalReservations: json['totalReservations'] as int,
      reservationsGrowthPercent: (json['reservationsGrowthPercent'] as num)
          .toDouble(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      revenueGrowthPercent: (json['revenueGrowthPercent'] as num).toDouble(),
      categoryPopularity: (json['categoryPopularity'] as List)
          .map((e) => CategoryPopularity.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivities: (json['recentActivities'] as List)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
