using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IProfileService
    {
        Task<ProfileResponse> GetMyProfileAsync(int userId);
        Task<ProfileResponse> UpdateMyProfileAsync(int userId, ProfileUpdateRequest request);
        Task ChangePasswordAsync(int userId, ChangePasswordRequest request);
    }
}