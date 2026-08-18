import 'activity.dart';

class RecommendedActivity {
  final Activity activity;
  final String reason;

  RecommendedActivity({required this.activity, required this.reason});

  factory RecommendedActivity.fromJson(Map<String, dynamic> json) {
    return RecommendedActivity(
      activity: Activity.fromJson(json['activity'] as Map<String, dynamic>),
      reason: json['reason'] as String? ?? '',
    );
  }
}
