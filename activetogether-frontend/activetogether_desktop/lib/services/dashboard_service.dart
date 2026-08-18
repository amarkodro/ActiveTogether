import '../models/admin_dashboard_stats.dart';
import 'api_client.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<AdminDashboardStats> getAdminDashboard() async {
    final response = await _apiClient.dio.get('/api/Dashboard/admin');
    return AdminDashboardStats.fromJson(response.data as Map<String, dynamic>);
  }
}
