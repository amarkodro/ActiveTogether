using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IAuthService
    {
        Task<UserResponse> RegisterAsync(RegisterRequest request);
        Task<LoginResponse> LoginAsync(LoginRequest request);
    }
}