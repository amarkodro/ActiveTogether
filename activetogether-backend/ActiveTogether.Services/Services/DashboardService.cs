using ActiveTogether.Model.Enums;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class DashboardService : IDashboardService
    {
        private readonly ActiveTogetherDbContext _context;

        public DashboardService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<AdminDashboardResponse> GetAdminDashboardAsync()
        {
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

            var totalUsers = await _context.Users.CountAsync();
            var usersBefore = await _context.Users.CountAsync(u => u.CreatedAt < startOfMonth);

            var totalActivities = await _context.Activities.CountAsync();
            var activitiesBefore = await _context.Activities.CountAsync(a => a.CreatedAt < startOfMonth);

            var totalReservations = await _context.Reservations.CountAsync();
            var reservationsBefore = await _context.Reservations.CountAsync(r => r.CreatedAt < startOfMonth);

            var totalRevenue = await _context.Payments
                .Where(p => p.Status == PaymentStatus.Completed)
                .SumAsync(p => (decimal?)p.Amount) ?? 0;

            var revenueBefore = await _context.Payments
                .Where(p => p.Status == PaymentStatus.Completed && p.PaidAt != null && p.PaidAt < startOfMonth)
                .SumAsync(p => (decimal?)p.Amount) ?? 0;

            var categoryPopularity = await _context.Activities
                .Include(a => a.Category)
                .GroupBy(a => a.Category!.Name)
                .Select(g => new CategoryPopularityItem
                {
                    CategoryName = g.Key,
                    Count = g.Count()
                })
                .OrderByDescending(c => c.Count)
                .ToListAsync();

            var recentActivities = await _context.Activities
                .Include(a => a.Organizer)
                .OrderByDescending(a => a.CreatedAt)
                .Take(5)
                .Select(a => new RecentActivityItem
                {
                    Id = a.Id,
                    Name = a.Name,
                    OrganizerName = a.Organizer != null ? a.Organizer.FirstName + " " + a.Organizer.LastName : "",
                    Status = a.Status.ToString()
                })
                .ToListAsync();

            return new AdminDashboardResponse
            {
                TotalUsers = totalUsers,
                UsersGrowthPercent = CalculateGrowth(totalUsers, usersBefore),

                TotalActivities = totalActivities,
                ActivitiesGrowthPercent = CalculateGrowth(totalActivities, activitiesBefore),

                TotalReservations = totalReservations,
                ReservationsGrowthPercent = CalculateGrowth(totalReservations, reservationsBefore),

                TotalRevenue = totalRevenue,
                RevenueGrowthPercent = CalculateGrowth((double)totalRevenue, (double)revenueBefore),

                CategoryPopularity = categoryPopularity,
                RecentActivities = recentActivities
            };
        }

        private static double CalculateGrowth(double current, double previous)
        {
            if (previous <= 0)
                return current > 0 ? 100 : 0;

            return Math.Round((current - previous) / previous * 100, 1);
        }

        public async Task<OrganizerDashboardResponse> GetOrganizerDashboardAsync(int organizerId)
        {
            var now = DateTime.UtcNow;
            var today = now.Date;
            var diff = (7 + (today.DayOfWeek - DayOfWeek.Monday)) % 7;
            var startOfWeek = today.AddDays(-diff);
            var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

            var organizerActivities = _context.Activities
                .Where(a => a.OrganizerId == organizerId);

            var activeActivitiesCount = await organizerActivities
                .CountAsync(a => a.Status == ActivityStatus.Active);
            var newActivitiesThisWeek = await organizerActivities
                .CountAsync(a => a.CreatedAt >= startOfWeek);

            var organizerReservations = _context.Reservations
                .Where(r => r.Activity!.OrganizerId == organizerId && r.Status != ReservationStatus.Cancelled);

            var totalParticipants = await organizerReservations.CountAsync();
            var newParticipantsThisWeek = await organizerReservations
                .CountAsync(r => r.CreatedAt >= startOfWeek);

            var monthlyRevenue = await (
                from p in _context.Payments
                join r in _context.Reservations on p.ReservationId equals r.Id
                where r.Activity!.OrganizerId == organizerId
                   && p.Status == PaymentStatus.Completed
                   && p.PaidAt != null && p.PaidAt >= startOfMonth
                select p.Amount
            ).SumAsync();

            var averageRating = await _context.Ratings
                .Where(r => r.Activity!.OrganizerId == organizerId)
                .Select(r => (double?)r.Score)
                .AverageAsync() ?? 0;

            // Reserved count se izračuna u SQL-u (jedan correlated subquery po aktivnosti);
            // FillRatio je trivijalno dijeljenje pa se radi nad već malim, filtriranim
            // rezultatom (samo organizatorove aktivne aktivnosti), ne nad cijelim skupom.
            var activityFillRates = (await organizerActivities
                    .Where(a => a.Status == ActivityStatus.Active)
                    .Select(a => new
                    {
                        a.Name,
                        a.Capacity,
                        ReservedCount = a.Reservations.Count(r => r.Status != ReservationStatus.Cancelled)
                    })
                    .ToListAsync())
                .Select(x => new ActivityFillRateItem
                {
                    ActivityName = x.Name,
                    ReservedCount = x.ReservedCount,
                    Capacity = x.Capacity,
                    FillRatio = x.Capacity == 0 ? 0 : (double)x.ReservedCount / x.Capacity
                })
                .OrderByDescending(x => x.FillRatio)
                .ToList();

            var recentReservations = await organizerReservations
                .Include(r => r.User)
                .OrderByDescending(r => r.CreatedAt)
                .Take(5)
                .Select(r => new RecentReservationItem
                {
                    UserName = r.User != null ? r.User.FirstName + " " + r.User.LastName : "",
                    CreatedAt = r.CreatedAt,
                    Status = r.Status.ToString()
                })
                .ToListAsync();

            return new OrganizerDashboardResponse
            {
                ActiveActivitiesCount = activeActivitiesCount,
                NewActivitiesThisWeek = newActivitiesThisWeek,
                TotalParticipants = totalParticipants,
                NewParticipantsThisWeek = newParticipantsThisWeek,
                MonthlyRevenue = monthlyRevenue,
                AverageRating = averageRating,
                ActivityFillRates = activityFillRates,
                RecentReservations = recentReservations
            };
        }
    }
}