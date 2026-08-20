using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IRatingService
    {
        Task<RatingResponse> CreateAsync(RatingCreateRequest request, int userId);
    }
}