using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<PagedResult<RecommendedActivityResponse>> GetRecommendationsAsync(int userId, RecommendationSearchObject search);
    }
}