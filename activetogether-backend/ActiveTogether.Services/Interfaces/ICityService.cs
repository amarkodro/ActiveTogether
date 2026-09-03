using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface ICityService
    {
        Task<List<CityResponse>> GetAllAsync();
        Task<PagedResult<CityResponse>> GetPagedAsync(CitySearchObject search);
        Task<CityResponse> GetByIdAsync(int id);
        Task<CityResponse> CreateAsync(CityUpsertRequest request);
        Task<CityResponse> UpdateAsync(int id, CityUpsertRequest request);
        Task DeleteAsync(int id);
    }
}
