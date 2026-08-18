namespace ActiveTogether.Model.Responses;

public class AdminDashboardResponse
{
    public int TotalUsers { get; set; }
    public double UsersGrowthPercent { get; set; }

    public int TotalActivities { get; set; }
    public double ActivitiesGrowthPercent { get; set; }

    public int TotalReservations { get; set; }
    public double ReservationsGrowthPercent { get; set; }

    public decimal TotalRevenue { get; set; }
    public double RevenueGrowthPercent { get; set; }

    public List<CategoryPopularityItem> CategoryPopularity { get; set; } = new();
    public List<RecentActivityItem> RecentActivities { get; set; } = new();
}

public class CategoryPopularityItem
{
    public string CategoryName { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class RecentActivityItem
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string OrganizerName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}