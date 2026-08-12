using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IActivityService
    {
        Task<PagedResult<ActivityResponse>> GetAllAsync(ActivitySearchObject search, int? organizerId, bool includeAllStatuses, int? currentUserId);
        Task<ActivityResponse> GetByIdAsync(int id, int? currentUserId);
        Task<ActivityResponse> CreateAsync(ActivityUpsertRequest request, int organizerId);
        Task<ActivityResponse> UpdateAsync(int id, ActivityUpsertRequest request, int currentUserId, bool isAdmin);
        Task<ActivityResponse> CancelAsync(int id, int currentUserId, bool isAdmin);
    }
}