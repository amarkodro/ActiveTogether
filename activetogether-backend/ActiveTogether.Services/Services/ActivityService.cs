using ActiveTogether.Model.Enums;
using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class ActivityService : IActivityService
    {
        private const int MaxPageSize = 100;

        private readonly ActiveTogetherDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly IPaymentService _paymentService;

        public ActivityService(ActiveTogetherDbContext context, INotificationService notificationService, IPaymentService paymentService)
        {
            _context = context;
            _notificationService = notificationService;
            _paymentService = paymentService;
        }

        public async Task<PagedResult<ActivityResponse>> GetAllAsync(ActivitySearchObject search, int? organizerId, bool includeAllStatuses, int? currentUserId)
        {
            var query = _context.Activities
                .Include(a => a.Category)
                .Include(a => a.ActivityType)
                .Include(a => a.Location)
                .Include(a => a.Organizer)
                .AsQueryable();

            if (!includeAllStatuses)
                query = query.Where(a => a.Status == ActivityStatus.Active);

            if (organizerId.HasValue)
                query = query.Where(a => a.OrganizerId == organizerId.Value);

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(a => a.Name.Contains(search.Name));

            if (search.CategoryId.HasValue)
                query = query.Where(a => a.CategoryId == search.CategoryId.Value);

            if (search.Status.HasValue)
                query = query.Where(a => a.Status == search.Status.Value);

            if (search.ActivityTypeId.HasValue)
                query = query.Where(a => a.ActivityTypeId == search.ActivityTypeId.Value);

            if (search.CityId.HasValue)
                query = query.Where(a => a.Location!.CityId == search.CityId.Value);

            if (search.IsFree.HasValue)
                query = query.Where(a => a.IsFree == search.IsFree.Value);

            if (search.DateFrom.HasValue)
                query = query.Where(a => a.DateTime >= search.DateFrom.Value);

            if (search.DateTo.HasValue)
                query = query.Where(a => a.DateTime <= search.DateTo.Value);

            var totalCount = await query.CountAsync();

            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var activities = await query
                .OrderBy(a => a.DateTime)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var activityIds = activities.Select(a => a.Id).ToList();

            var reservedCounts = await _context.Reservations
                .Where(r => activityIds.Contains(r.ActivityId) && r.Status != ReservationStatus.Cancelled)
                .GroupBy(r => r.ActivityId)
                .Select(g => new { ActivityId = g.Key, Count = g.Count() })
                .ToListAsync();

            var reservedLookup = reservedCounts.ToDictionary(x => x.ActivityId, x => x.Count);

            var ratingStats = await _context.Ratings
                .Where(r => activityIds.Contains(r.ActivityId))
                .GroupBy(r => r.ActivityId)
                .Select(g => new { ActivityId = g.Key, Average = g.Average(x => x.Score), Count = g.Count() })
                .ToListAsync();

            var ratingLookup = ratingStats.ToDictionary(x => x.ActivityId, x => x);

            var items = activities
                .Select(a =>
                {
                    var rating = ratingLookup.GetValueOrDefault(a.Id);
                    return MapToResponse(a, reservedLookup.GetValueOrDefault(a.Id), rating?.Average, rating?.Count ?? 0);
                })
                .ToList();

            if (currentUserId.HasValue && (!string.IsNullOrWhiteSpace(search.Name) || search.CategoryId.HasValue || search.CityId.HasValue))
            {
                _context.SearchHistories.Add(new SearchHistory
                {
                    UserId = currentUserId.Value,
                    SearchTerm = search.Name,
                    CategoryId = search.CategoryId,
                    CityId = search.CityId,
                    CreatedAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }

            return new PagedResult<ActivityResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<ActivityResponse> GetByIdAsync(int id, int? currentUserId)
        {
            var activity = await _context.Activities
                .Include(a => a.Category)
                .Include(a => a.ActivityType)
                .Include(a => a.Location)
                .Include(a => a.Organizer)
                .FirstOrDefaultAsync(a => a.Id == id)
                ?? throw new NotFoundException($"Aktivnost sa Id {id} ne postoji.");

            var reservedCount = await _context.Reservations
                .CountAsync(r => r.ActivityId == id && r.Status != ReservationStatus.Cancelled);

            var ratings = await _context.Ratings.Where(r => r.ActivityId == id).ToListAsync();
            var averageRating = ratings.Count > 0 ? ratings.Average(r => r.Score) : (double?)null;
            var ratingCount = ratings.Count;

            if (currentUserId.HasValue)
            {
                _context.ActivityViews.Add(new ActivityView
                {
                    UserId = currentUserId.Value,
                    ActivityId = id,
                    CreatedAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }

            return MapToResponse(activity, reservedCount, averageRating, ratingCount);
        }

        public async Task<ActivityResponse> GetByIdAsync(int id)
        {
            var activity = await _context.Activities
                .Include(a => a.Category)
                .Include(a => a.ActivityType)
                .Include(a => a.Location)
                .Include(a => a.Organizer)
                .FirstOrDefaultAsync(a => a.Id == id)
                ?? throw new NotFoundException($"Aktivnost sa Id {id} ne postoji.");

            var reservedCount = await _context.Reservations
                .CountAsync(r => r.ActivityId == id && r.Status != ReservationStatus.Cancelled);

            var ratings = await _context.Ratings.Where(r => r.ActivityId == id).ToListAsync();
            var averageRating = ratings.Count > 0 ? ratings.Average(r => r.Score) : (double?)null;
            var ratingCount = ratings.Count;

            return MapToResponse(activity, reservedCount, averageRating, ratingCount);
        }

        public async Task<ActivityResponse> CreateAsync(ActivityUpsertRequest request, int organizerId)
        {
            await ValidateReferencesAsync(request);
            ValidateBusinessRules(request);

            var activity = new Activity
            {
                Name = request.Name,
                Description = request.Description,
                CategoryId = request.CategoryId,
                ActivityTypeId = request.ActivityTypeId,
                LocationId = request.LocationId,
                OrganizerId = organizerId,
                DateTime = request.DateTime,
                Capacity = request.Capacity,
                IsFree = request.IsFree,
                Price = request.IsFree ? null : request.Price,
                ImageUrl = request.ImageUrl,
                Status = ActivityStatus.Active,
                CreatedAt = DateTime.UtcNow
            };

            _context.Activities.Add(activity);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(activity.Id);
        }

        public async Task<ActivityResponse> UpdateAsync(int id, ActivityUpsertRequest request, int currentUserId, bool isAdmin)
        {
            var activity = await _context.Activities.FindAsync(id)
                ?? throw new NotFoundException($"Aktivnost sa Id {id} ne postoji.");

            EnsureOwnership(activity, currentUserId, isAdmin);

            if (activity.Status is ActivityStatus.Cancelled or ActivityStatus.Completed)
                throw new BusinessException("Otkazana ili završena aktivnost se ne može uređivati.");

            await ValidateReferencesAsync(request);
            ValidateBusinessRules(request);

            var reservedCount = await _context.Reservations
                .CountAsync(r => r.ActivityId == id && r.Status != ReservationStatus.Cancelled);

            if (request.Capacity < reservedCount)
                throw new BusinessException($"Kapacitet ne može biti manji od broja postojećih rezervacija ({reservedCount}).");

            activity.Name = request.Name;
            activity.Description = request.Description;
            activity.CategoryId = request.CategoryId;
            activity.ActivityTypeId = request.ActivityTypeId;
            activity.LocationId = request.LocationId;
            activity.DateTime = request.DateTime;
            activity.Capacity = request.Capacity;
            activity.IsFree = request.IsFree;
            activity.Price = request.IsFree ? null : request.Price;
            activity.ImageUrl = request.ImageUrl;
            activity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return await GetByIdAsync(activity.Id);
        }

        public async Task<ActivityResponse> CancelAsync(int id, int currentUserId, bool isAdmin)
        {
            var activity = await _context.Activities.FindAsync(id)
                ?? throw new NotFoundException($"Aktivnost sa Id {id} ne postoji.");

            EnsureOwnership(activity, currentUserId, isAdmin);

            if (!StatusTransitions.CanTransition(activity.Status, ActivityStatus.Cancelled))
                throw new BusinessException("Aktivnost je već otkazana ili završena.");

            activity.Status = ActivityStatus.Cancelled;
            activity.UpdatedAt = DateTime.UtcNow;

            var reservations = await _context.Reservations
                .Where(r => r.ActivityId == id &&
                    (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Confirmed))
                .ToListAsync();

            foreach (var reservation in reservations)
            {
                reservation.Status = ReservationStatus.Cancelled;
                reservation.CancellationReason = "Aktivnost je otkazana od strane organizatora.";
                reservation.CancelledAt = DateTime.UtcNow;
                reservation.CancelledByUserId = currentUserId;
            }

            await _context.SaveChangesAsync();

            foreach (var reservation in reservations)
            {
                await _paymentService.RefundPaymentAsync(reservation.Id);

                await _notificationService.NotifyAsync(
                    reservation.UserId,
                    NotificationType.ReservationCancelled,
                    "Aktivnost otkazana",
                    $"Aktivnost \"{activity.Name}\" je otkazana od strane organizatora. Vaša rezervacija je otkazana, a eventualna uplata će biti refundirana.");
            }

            return await GetByIdAsync(activity.Id);
        }

        public async Task<ActivityResponse> CompleteAsync(int id, int currentUserId, bool isAdmin)
        {
            var activity = await _context.Activities.FindAsync(id)
                ?? throw new NotFoundException($"Aktivnost sa Id {id} ne postoji.");

            EnsureOwnership(activity, currentUserId, isAdmin);

            if (!StatusTransitions.CanTransition(activity.Status, ActivityStatus.Completed))
                throw new BusinessException("Aktivnost se ne može označiti kao završena iz trenutnog statusa.");

            if (activity.DateTime > DateTime.UtcNow)
                throw new BusinessException("Aktivnost još nije održana.");

            activity.Status = ActivityStatus.Completed;
            activity.UpdatedAt = DateTime.UtcNow;

            var reservations = await _context.Reservations
                .Where(r => r.ActivityId == id &&
                    (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Pending))
                .ToListAsync();

            foreach (var reservation in reservations)
            {
                if (reservation.Status == ReservationStatus.Confirmed)
                {
                    reservation.Status = ReservationStatus.Completed;
                    reservation.CompletedAt = DateTime.UtcNow;
                }
                else
                {
                    reservation.Status = ReservationStatus.Cancelled;
                    reservation.CancellationReason = "Aktivnost je završena bez potvrde rezervacije.";
                    reservation.CancelledAt = DateTime.UtcNow;
                    reservation.CancelledByUserId = currentUserId;
                }
            }

            await _context.SaveChangesAsync();

            foreach (var reservation in reservations)
            {
                if (reservation.Status == ReservationStatus.Completed)
                {
                    await _notificationService.NotifyAsync(
                        reservation.UserId,
                        NotificationType.ReservationCompleted,
                        "Aktivnost završena",
                        $"Aktivnost \"{activity.Name}\" je završena. Ostavite ocjenu i komentar!");
                }
                else
                {
                    await _notificationService.NotifyAsync(
                        reservation.UserId,
                        NotificationType.ReservationCancelled,
                        "Rezervacija otkazana",
                        $"Vaša rezervacija za aktivnost \"{activity.Name}\" je otkazana jer nije potvrđena prije termina.");
                }
            }

            return await GetByIdAsync(activity.Id);
        }

        private static void EnsureOwnership(Activity activity, int currentUserId, bool isAdmin)
        {
            if (!isAdmin && activity.OrganizerId != currentUserId)
                throw new BusinessException("Nemate dozvolu za izmjenu ove aktivnosti.");
        }

        private static void ValidateBusinessRules(ActivityUpsertRequest request)
        {
            if (request.DateTime <= DateTime.UtcNow)
                throw new BusinessException("Datum i vrijeme aktivnosti moraju biti u budućnosti.");

            if (request.Capacity <= 0)
                throw new BusinessException("Kapacitet mora biti veći od nule.");

            if (!request.IsFree && (request.Price is null || request.Price <= 0))
                throw new BusinessException("Premium aktivnost mora imati cijenu veću od nule.");
        }

        private async Task ValidateReferencesAsync(ActivityUpsertRequest request)
        {
            if (!await _context.Categories.AnyAsync(c => c.Id == request.CategoryId))
                throw new NotFoundException($"Kategorija sa Id {request.CategoryId} ne postoji.");

            if (!await _context.ActivityTypes.AnyAsync(t => t.Id == request.ActivityTypeId))
                throw new NotFoundException($"Tip aktivnosti sa Id {request.ActivityTypeId} ne postoji.");

            if (!await _context.Locations.AnyAsync(l => l.Id == request.LocationId))
                throw new NotFoundException($"Lokacija sa Id {request.LocationId} ne postoji.");
        }

        private static ActivityResponse MapToResponse(Activity activity, int reservedCount, double? averageRating, int ratingCount)
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
                LocationLatitude = activity.Location?.Latitude ?? 0,
                LocationLongitude = activity.Location?.Longitude ?? 0,
                OrganizerId = activity.OrganizerId,
                OrganizerName = activity.Organizer is null ? string.Empty : $"{activity.Organizer.FirstName} {activity.Organizer.LastName}",
                DateTime = activity.DateTime,
                Capacity = activity.Capacity,
                ReservedCount = reservedCount,
                IsFree = activity.IsFree,
                Price = activity.Price,
                ImageUrl = activity.ImageUrl,
                Status = activity.Status.ToString(),
                AverageRating = averageRating,
                RatingCount = ratingCount
            };
        }
    }
}
