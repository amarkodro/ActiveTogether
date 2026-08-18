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
    }
}