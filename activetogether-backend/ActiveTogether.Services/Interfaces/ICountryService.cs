using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface ICountryService
    {
        Task<List<CountryResponse>> GetAllAsync();
        Task<PagedResult<CountryResponse>> GetPagedAsync(ReferenceSearchObject search);
        Task<CountryResponse> GetByIdAsync(int id);
        Task<CountryResponse> CreateAsync(CountryUpsertRequest request);
        Task<CountryResponse> UpdateAsync(int id, CountryUpsertRequest request);
        Task DeleteAsync(int id);
    }
}
