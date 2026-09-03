using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface ILocationService
    {
        Task<List<LocationResponse>> GetAllAsync();
        Task<PagedResult<LocationResponse>> GetPagedAsync(LocationSearchObject search);
        Task<LocationResponse> GetByIdAsync(int id);
        Task<LocationResponse> CreateAsync(LocationUpsertRequest request);
        Task<LocationResponse> UpdateAsync(int id, LocationUpsertRequest request);
        Task DeleteAsync(int id);
    }
}
