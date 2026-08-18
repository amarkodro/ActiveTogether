using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IDashboardService
    {
        Task<AdminDashboardResponse> GetAdminDashboardAsync();
        Task<OrganizerDashboardResponse> GetOrganizerDashboardAsync(int organizerId);
    }
}