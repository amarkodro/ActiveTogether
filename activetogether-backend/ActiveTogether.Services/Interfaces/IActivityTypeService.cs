using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IActivityTypeService
    {
        Task<List<ActivityTypeResponse>> GetAllAsync();
        Task<ActivityTypeResponse> GetByIdAsync(int id);
        Task<ActivityTypeResponse> CreateAsync(ActivityTypeUpsertRequest request);
        Task<ActivityTypeResponse> UpdateAsync(int id, ActivityTypeUpsertRequest request);
        Task DeleteAsync(int id);
    }
}