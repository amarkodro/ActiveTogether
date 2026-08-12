using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using ActiveTogether.Model.Enums;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class RecommendationService : IRecommendationService
    {
        private const int MaxPageSize = 100;

        private const double ReservationWeight = 3.0;
        private const double ViewWeight = 2.0;
        private const double SearchWeight = 1.0;

        private readonly ActiveTogetherDbContext _context;

        public RecommendationService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<RecommendedActivityResponse>> GetRecommendationsAsync(int userId, RecommendationSearchObject search)
        {
            var user = await _context.Users.FindAsync(userId);

            var candidates = await _context.Activities
                .Include(a => a.Category)
                .Include(a => a.ActivityType)
                .Include(a => a.Location)
                .Include(a => a.Organizer)
                .Where(a => a.Status == ActivityStatus.Active && a.DateTime > DateTime.UtcNow && a.OrganizerId != userId)
                .ToListAsync();

            var candidateIds = candidates.Select(a => a.Id).ToList();

            var reservedCounts = await _context.Reservations
                .Where(r => candidateIds.Contains(r.ActivityId) && r.Status != ReservationStatus.Cancelled)
                .GroupBy(r => r.ActivityId)
                .Select(g => new { ActivityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.ActivityId, x => x.Count);

            var alreadyReservedIds = await _context.Reservations
                .Where(r => r.UserId == userId && r.Status != ReservationStatus.Cancelled && candidateIds.Contains(r.ActivityId))
                .Select(r => r.ActivityId)
                .ToListAsync();

            candidates = candidates
                .Where(a => !alreadyReservedIds.Contains(a.Id) && reservedCounts.GetValueOrDefault(a.Id) < a.Capacity)
                .ToList();
            candidateIds = candidates.Select(a => a.Id).ToList();

            var recentThreshold = DateTime.UtcNow.AddDays(-14);
            var recentCounts = await _context.Reservations
                .Where(r => candidateIds.Contains(r.ActivityId) && r.Status != ReservationStatus.Cancelled && r.CreatedAt >= recentThreshold)
                .GroupBy(r => r.ActivityId)
                .Select(g => new { ActivityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.ActivityId, x => x.Count);

            var avgRatings = await _context.Ratings
                .Where(r => candidateIds.Contains(r.ActivityId))
                .GroupBy(r => r.ActivityId)
                .Select(g => new { ActivityId = g.Key, Avg = g.Average(x => x.Score) })
                .ToDictionaryAsync(x => x.ActivityId, x => x.Avg);

            // --- korisnički signali ---
            var userReservations = await _context.Reservations
                .Include(r => r.Activity)
                .ThenInclude(a => a!.Location)
                .Where(r => r.UserId == userId && r.Status != ReservationStatus.Cancelled)
                .ToListAsync();

            var userViews = await _context.ActivityViews
                .Include(v => v.Activity)
                .ThenInclude(a => a!.Location)
                .Where(v => v.UserId == userId)
                .ToListAsync();

            var userSearches = await _context.SearchHistories
                .Where(s => s.UserId == userId)
                .ToListAsync();

            var categoryWeights = new Dictionary<int, double>();
            var cityWeights = new Dictionary<int, double>();
            double freeWeight = 0, premiumWeight = 0;

            void AddCategory(int? categoryId, double weight)
            {
                if (!categoryId.HasValue) return;
                categoryWeights[categoryId.Value] = categoryWeights.GetValueOrDefault(categoryId.Value) + weight;
            }

            void AddCity(int? cityId, double weight)
            {
                if (!cityId.HasValue) return;
                cityWeights[cityId.Value] = cityWeights.GetValueOrDefault(cityId.Value) + weight;
            }

            foreach (var r in userReservations)
            {
                if (r.Activity is null) continue;
                AddCategory(r.Activity.CategoryId, ReservationWeight);
                AddCity(r.Activity.Location?.CityId, ReservationWeight);
                if (r.Activity.IsFree) freeWeight += ReservationWeight; else premiumWeight += ReservationWeight;
            }

            foreach (var v in userViews)
            {
                if (v.Activity is null) continue;
                AddCategory(v.Activity.CategoryId, ViewWeight);
                AddCity(v.Activity.Location?.CityId, ViewWeight);
                if (v.Activity.IsFree) freeWeight += ViewWeight; else premiumWeight += ViewWeight;
            }

            foreach (var s in userSearches)
            {
                AddCategory(s.CategoryId, SearchWeight);
                AddCity(s.CityId, SearchWeight);
            }

            var totalSignals = userReservations.Count + userViews.Count + userSearches.Count;
            var isColdStart = totalSignals == 0;

            var maxCategoryWeight = categoryWeights.Count > 0 ? categoryWeights.Values.Max() : 0;
            var maxCityWeight = cityWeights.Count > 0 ? cityWeights.Values.Max() : 0;
            var preferFree = freeWeight >= premiumWeight;

            var maxReservedCount = candidateIds.Count > 0 ? candidateIds.Select(id => reservedCounts.GetValueOrDefault(id)).DefaultIfEmpty(0).Max() : 0;
            var maxRecentCount = candidateIds.Count > 0 ? candidateIds.Select(id => recentCounts.GetValueOrDefault(id)).DefaultIfEmpty(0).Max() : 0;

            var scored = candidates.Select(a =>
            {
                var reservedCount = reservedCounts.GetValueOrDefault(a.Id);
                var recentCount = recentCounts.GetValueOrDefault(a.Id);
                var avgRating = avgRatings.GetValueOrDefault(a.Id);
                var fillRatio = a.Capacity > 0 ? (double)reservedCount / a.Capacity : 0;

                var reservedNorm = maxReservedCount > 0 ? (double)reservedCount / maxReservedCount : 0;
                var ratingNorm = avgRating / 5.0;
                var trendNorm = maxRecentCount > 0 ? (double)recentCount / maxRecentCount : 0;

                var popularityScore = 0.4 * reservedNorm + 0.3 * ratingNorm + 0.2 * trendNorm + 0.1 * fillRatio;

                double categoryComponent = 0, cityComponent = 0, priceComponent = 0;

                if (!isColdStart)
                {
                    categoryComponent = maxCategoryWeight > 0 ? categoryWeights.GetValueOrDefault(a.CategoryId) / maxCategoryWeight : 0;
                    var cityId = a.Location?.CityId;
                    cityComponent = cityId.HasValue && maxCityWeight > 0 ? cityWeights.GetValueOrDefault(cityId.Value) / maxCityWeight : 0;
                    priceComponent = (a.IsFree == preferFree) ? 1.0 : 0.0;
                }

                var contentScore = 0.5 * categoryComponent + 0.3 * cityComponent + 0.2 * priceComponent;

                var finalScore = isColdStart ? popularityScore : (0.6 * contentScore + 0.4 * popularityScore);

                string reason;
                if (isColdStart)
                {
                    reason = (user?.CityId.HasValue == true && a.Location?.CityId == user.CityId)
                        ? "Popularno u tvom gradu"
                        : "Popularno na platformi";
                }
                else if (categoryComponent * 0.5 >= cityComponent * 0.3 && categoryComponent > 0)
                {
                    reason = $"Na osnovu tvojih aktivnosti u kategoriji {a.Category?.Name}";
                }
                else if (cityComponent > 0)
                {
                    reason = "Popularno u tvom gradu";
                }
                else
                {
                    reason = "Popularno na platformi";
                }

                return new { Activity = a, Score = finalScore, Reason = reason, ReservedCount = reservedCount };
            })
            .OrderByDescending(x => x.Score)
            .ToList();

            var totalCount = scored.Count;
            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var pageItems = scored
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(x => new RecommendedActivityResponse
                {
                    Activity = MapToActivityResponse(x.Activity, x.ReservedCount),
                    Reason = x.Reason
                })
                .ToList();

            return new PagedResult<RecommendedActivityResponse>
            {
                Items = pageItems,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        private static ActivityResponse MapToActivityResponse(Activity activity, int reservedCount)
        {
            return new ActivityResponse
            {
                Id = activity.Id,
                Name = activity.Name,
                Description = activity.Description,
                CategoryId = activity.CategoryId,
                CategoryName = activity.Category?.Name ?? string.Empty,
                ActivityTypeId = activity.ActivityTypeId,
                ActivityTypeName = activity.ActivityType?.Name ?? string.Empty,
                LocationId = activity.LocationId,
                LocationName = activity.Location?.Name ?? string.Empty,
                LocationAddress = activity.Location?.Address ?? string.Empty,
                OrganizerId = activity.OrganizerId,
                OrganizerName = activity.Organizer is null ? string.Empty : $"{activity.Organizer.FirstName} {activity.Organizer.LastName}",
                DateTime = activity.DateTime,
                Capacity = activity.Capacity,
                ReservedCount = reservedCount,
                IsFree = activity.IsFree,
                Price = activity.Price,
                ImageUrl = activity.ImageUrl,
                Status = activity.Status.ToString()
            };
        }
    }
}