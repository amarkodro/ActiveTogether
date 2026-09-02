using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class FavoriteService : IFavoriteService
    {
        private const int MaxPageSize = 100;

        private readonly ActiveTogetherDbContext _context;
        private readonly IActivityService _activityService;

        public FavoriteService(ActiveTogetherDbContext context, IActivityService activityService)
        {
            _context = context;
            _activityService = activityService;
        }

        public async Task AddAsync(int userId, int activityId)
        {
            var activityExists = await _context.Activities.AnyAsync(a => a.Id == activityId);
            if (!activityExists)
                throw new NotFoundException($"Aktivnost sa Id {activityId} ne postoji.");

            var alreadyExists = await _context.Favorites
                .AnyAsync(f => f.UserId == userId && f.ActivityId == activityId);

            if (alreadyExists)
                return;

            _context.Favorites.Add(new Favorite
            {
                UserId = userId,
                ActivityId = activityId,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
        }

        public async Task RemoveAsync(int userId, int activityId)
        {
            var favorite = await _context.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.ActivityId == activityId);

            if (favorite is null)
                return;

            _context.Favorites.Remove(favorite);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> IsFavoriteAsync(int userId, int activityId)
        {
            return await _context.Favorites
                .AnyAsync(f => f.UserId == userId && f.ActivityId == activityId);
        }

        public async Task<PagedResult<ActivityResponse>> GetMyFavoritesAsync(int userId, int page, int pageSize)
        {
            pageSize = Math.Clamp(pageSize, 1, MaxPageSize);
            page = Math.Max(page, 1);

            var query = _context.Favorites
                .Where(f => f.UserId == userId)
                .OrderByDescending(f => f.CreatedAt);

            var totalCount = await query.CountAsync();

            var activityIds = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(f => f.ActivityId)
                .ToListAsync();

            var items = new List<ActivityResponse>();
            foreach (var activityId in activityIds)
            {
                try
                {
                    items.Add(await _activityService.GetByIdAsync(activityId, null));
                }
                catch (NotFoundException)
                {
                    // aktivnost je u međuvremenu obrisana - preskoči je u listi omiljenih
                }
            }

            return new PagedResult<ActivityResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }
    }
}
