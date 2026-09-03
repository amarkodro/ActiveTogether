using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface ICategoryService
    {
        Task<List<CategoryResponse>> GetAllAsync();
        Task<PagedResult<CategoryResponse>> GetPagedAsync(ReferenceSearchObject search);
        Task<CategoryResponse> GetByIdAsync(int id);
        Task<CategoryResponse> CreateAsync(CategoryUpsertRequest request);
        Task<CategoryResponse> UpdateAsync(int id, CategoryUpsertRequest request);
        Task DeleteAsync(int id);
    }
}
