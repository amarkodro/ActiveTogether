using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IFavoriteService
    {
        Task AddAsync(int userId, int activityId);
        Task RemoveAsync(int userId, int activityId);
        Task<bool> IsFavoriteAsync(int userId, int activityId);
        Task<PagedResult<ActivityResponse>> GetMyFavoritesAsync(int userId, int page, int pageSize);
    }
}
