using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IUserService
    {
        Task<PagedResult<UserListResponse>> GetAllAsync(UserSearchObject search);
        Task<UserListResponse> GetByIdAsync(int id);
        Task<UserListResponse> UpdateAsync(int id, UserUpdateRequest request);
        Task SetActiveStatusAsync(int id, bool isActive);
    }
}