namespace ActiveTogether.Model.Responses
{
    public class OrganizerDashboardResponse
    {
        public int ActiveActivitiesCount { get; set; }
        public int NewActivitiesThisWeek { get; set; }
        public int TotalParticipants { get; set; }
        public int NewParticipantsThisWeek { get; set; }
        public decimal MonthlyRevenue { get; set; }
        public double AverageRating { get; set; }
        public List<ActivityFillRateItem> ActivityFillRates { get; set; } = new();
        public List<RecentReservationItem> RecentReservations { get; set; } = new();
    }

    public class ActivityFillRateItem
    {
        public string ActivityName { get; set; } = string.Empty;
        public int ReservedCount { get; set; }
        public int Capacity { get; set; }
        public double FillRatio { get; set; }
    }

    public class RecentReservationItem
    {
        public string UserName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}