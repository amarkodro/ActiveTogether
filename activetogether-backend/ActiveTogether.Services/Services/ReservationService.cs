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
    public class ReservationService : IReservationService
    {
        private const int MaxPageSize = 100;

        // Jedinstveno mjesto koje definiše koliko prije termina se rezervacija još može
        // otkazati (uz automatski refund). TimeSpan.Zero znači "dok aktivnost ne počne".
        // UI samo prati ovu odluku (activityDateTime - CancellationCutoff).
        private static readonly TimeSpan CancellationCutoff = TimeSpan.Zero;

        private readonly ActiveTogetherDbContext _context;
        private readonly IPaymentService _paymentService;
        private readonly INotificationService _notificationService;

        public ReservationService(ActiveTogetherDbContext context, IPaymentService paymentService, INotificationService notificationService)
        {
            _context = context;
            _paymentService = paymentService;
            _notificationService = notificationService;
        }

        public async Task<PagedResult<ReservationResponse>> GetMyReservationsAsync(int userId, ReservationSearchObject search)
        {
            var query = _context.Reservations
                .Include(r => r.Activity)
                .Include(r => r.User)
                .Include(r => r.Payment)
                .Where(r => r.UserId == userId);

            query = ApplyCommonFilters(query, search);
            return await ToPagedResultAsync(query, search);
        }
        public async Task<PagedResult<ReservationResponse>> GetForOrganizerAsync(int organizerId, ReservationSearchObject search)
        {
            var query = _context.Reservations
                .Include(r => r.Activity)
                .Include(r => r.User)
                .Include(r => r.Payment)
                .Where(r => r.Activity!.OrganizerId == organizerId);

            query = ApplyCommonFilters(query, search);

            return await ToPagedResultAsync(query, search);
        }


        public async Task<PagedResult<ReservationResponse>> GetForActivityAsync(int activityId, ReservationSearchObject search, int currentUserId, bool isAdmin)
        {
            var activity = await _context.Activities.FindAsync(activityId)
                ?? throw new NotFoundException($"Aktivnost sa Id {activityId} ne postoji.");

            if (!isAdmin && activity.OrganizerId != currentUserId)
                throw new BusinessException("Nemate dozvolu za pregled rezervacija ove aktivnosti.");

            var query = _context.Reservations
                .Include(r => r.Activity)
                .Include(r => r.User)
                .Include(r => r.Payment)
                .Where(r => r.ActivityId == activityId);

            query = ApplyCommonFilters(query, search);

            return await ToPagedResultAsync(query, search);
        }

        public async Task<PagedResult<ReservationResponse>> GetAllAsync(ReservationSearchObject search)
        {
            var query = _context.Reservations
                .Include(r => r.Activity)
                .Include(r => r.User)
                .Include(r => r.Payment)
                .AsQueryable();

            query = ApplyCommonFilters(query, search);

            return await ToPagedResultAsync(query, search);
        }
        public async Task<ReservationResponse> CreateAsync(ReservationCreateRequest request, int userId)
        {
            var activity = await _context.Activities.FindAsync(request.ActivityId)
                ?? throw new NotFoundException($"Aktivnost sa Id {request.ActivityId} ne postoji.");

            var user = await _context.Users.FindAsync(userId)
               ?? throw new NotFoundException("Korisnik ne postoji.");

            if (activity.Status != ActivityStatus.Active)
                throw new BusinessException("Rezervacija je moguća samo za aktivne aktivnosti.");

            if (activity.DateTime <= DateTime.UtcNow)
                throw new BusinessException("Aktivnost je već počela ili je prošla, rezervacija nije moguća.");

            if (activity.OrganizerId == userId)
                throw new BusinessException("Ne možete rezervisati vlastitu aktivnost.");

            var hasActiveReservation = await _context.Reservations
                .AnyAsync(r => r.ActivityId == request.ActivityId && r.UserId == userId && r.Status != ReservationStatus.Cancelled);

            if (hasActiveReservation)
                throw new BusinessException("Već imate aktivnu rezervaciju za ovu aktivnost.");

            var reservedCount = await _context.Reservations
                .CountAsync(r => r.ActivityId == request.ActivityId && r.Status != ReservationStatus.Cancelled);

            if (reservedCount >= activity.Capacity)
                throw new BusinessException("Aktivnost je popunjena, rezervacija nije moguća.");

            var reservation = new Reservation
            {
                UserId = userId,
                ActivityId = request.ActivityId,
                Status = ReservationStatus.Pending,
                CreatedAt = DateTime.UtcNow
            };

            _context.Reservations.Add(reservation);
            await _context.SaveChangesAsync();

            PaymentInfoResponse? payment = null;

            if (!activity.IsFree)
            {
                try
                {
                    payment = await _paymentService.CreatePaymentIntentAsync(reservation.Id, activity.Price ?? 0);
                }
                catch (Exception)
                {
                    // Kompenzacija: inicijalizacija plaćanja nije uspjela, pa rezervacija
                    // ne smije ostati u bazi kao "Pending" - blokirala bi kapacitet i
                    // spriječila korisnika da ponovo pokuša, a nikad nije dobio funkcionalan
                    // payment tok.
                    _context.Reservations.Remove(reservation);
                    await _context.SaveChangesAsync();

                    throw new BusinessException("Inicijalizacija plaćanja nije uspjela. Pokušajte ponovo napraviti rezervaciju.");
                }
            }

            var response = await GetByIdWithMappingAsync(reservation.Id);
            response.Payment = payment;

            await _notificationService.NotifyAsync(
                activity.OrganizerId,
                NotificationType.NewReservation,
                "Nova rezervacija",
                $"Korisnik {user.FirstName} {user.LastName} je rezervisao aktivnost \"{activity.Name}\".");

            return response;
        }

        public async Task<ReservationResponse> ConfirmAsync(int id, int currentUserId, bool isAdmin)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Activity)
                .Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Rezervacija sa Id {id} ne postoji.");

            EnsureOrganizerOwnership(reservation, currentUserId, isAdmin);

            if (!StatusTransitions.CanTransition(reservation.Status, ReservationStatus.Confirmed))
                throw new BusinessException("Samo rezervacije na čekanju mogu biti potvrđene.");

            if (!reservation.Activity!.IsFree && reservation.Payment?.Status != PaymentStatus.Completed)
                throw new BusinessException("Rezervacija se ne može potvrditi dok plaćanje nije uspješno završeno.");

            reservation.Status = ReservationStatus.Confirmed;
            reservation.ConfirmedAt = DateTime.UtcNow;
            reservation.ConfirmedByUserId = currentUserId;

            await _context.SaveChangesAsync();

            await _notificationService.NotifyAsync(
               reservation.UserId,
               NotificationType.ReservationConfirmed,
               "Rezervacija potvrđena",
               $"Vaša rezervacija za aktivnost \"{reservation.Activity!.Name}\" je potvrđena.");

            return await GetByIdWithMappingAsync(reservation.Id);
        }

        public async Task<ReservationResponse> CompleteAsync(int id, int currentUserId, bool isAdmin)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Activity)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Rezervacija sa Id {id} ne postoji.");

            EnsureOrganizerOwnership(reservation, currentUserId, isAdmin);

            if (!StatusTransitions.CanTransition(reservation.Status, ReservationStatus.Completed))
                throw new BusinessException("Samo potvrđene rezervacije mogu biti označene kao završene.");

            if (reservation.Activity!.DateTime > DateTime.UtcNow)
                throw new BusinessException("Aktivnost još nije održana.");

            reservation.Status = ReservationStatus.Completed;
            reservation.CompletedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.NotifyAsync(
               reservation.UserId,
               NotificationType.ReservationCompleted,
               "Aktivnost završena",
               $"Aktivnost \"{reservation.Activity!.Name}\" je završena. Ostavite ocjenu i komentar!");

            return await GetByIdWithMappingAsync(reservation.Id);
        }

        public async Task<ReservationResponse> CancelAsync(int id, ReservationCancelRequest request, int currentUserId, bool isAdmin)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Activity)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Rezervacija sa Id {id} ne postoji.");

            var isOwner = reservation.UserId == currentUserId;
            var isOrganizer = reservation.Activity!.OrganizerId == currentUserId;

            if (!isOwner && !isOrganizer && !isAdmin)
                throw new BusinessException("Nemate dozvolu za otkazivanje ove rezervacije.");

            if (!StatusTransitions.CanTransition(reservation.Status, ReservationStatus.Cancelled))
                throw new BusinessException("Rezervacija je već otkazana ili završena.");

            if (DateTime.UtcNow >= reservation.Activity!.DateTime - CancellationCutoff)
                throw new BusinessException("Rezervacija se ne može otkazati nakon što je aktivnost počela.");

            if ((isOrganizer || isAdmin) && !isOwner && string.IsNullOrWhiteSpace(request.Reason))
                throw new BusinessException("Razlog otkazivanja je obavezan kada rezervaciju otkazuje organizator ili administrator.");

            reservation.Status = ReservationStatus.Cancelled;
            reservation.CancellationReason = request.Reason;
            reservation.CancelledAt = DateTime.UtcNow;
            reservation.CancelledByUserId = currentUserId;

            await _context.SaveChangesAsync();

            await _paymentService.RefundPaymentAsync(reservation.Id);

            if (!isOwner)
            {
                await _notificationService.NotifyAsync(
                    reservation.UserId,
                    NotificationType.ReservationCancelled,
                    "Rezervacija otkazana",
                    $"Vaša rezervacija za aktivnost \"{reservation.Activity!.Name}\" je otkazana. Razlog: {request.Reason}");
            }

            return await GetByIdWithMappingAsync(reservation.Id);
        }

        private static void EnsureOrganizerOwnership(Reservation reservation, int currentUserId, bool isAdmin)
        {
            if (!isAdmin && reservation.Activity!.OrganizerId != currentUserId)
                throw new BusinessException("Nemate dozvolu za upravljanje ovom rezervacijom.");
        }

        private static IQueryable<Reservation> ApplyCommonFilters(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            if (search.ActivityId.HasValue)
                query = query.Where(r => r.ActivityId == search.ActivityId.Value);

            if (!string.IsNullOrWhiteSpace(search.Status) && Enum.TryParse<ReservationStatus>(search.Status, true, out var status))
                query = query.Where(r => r.Status == status);

            return query;
        }

        private async Task<PagedResult<ReservationResponse>> ToPagedResultAsync(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            var totalCount = await query.CountAsync();

            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var reservations = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<ReservationResponse>
            {
                Items = reservations.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        private async Task<ReservationResponse> GetByIdWithMappingAsync(int id)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Activity)
                .Include(r => r.User)
                .Include(r => r.Payment)
                .FirstAsync(r => r.Id == id);

            return MapToResponse(reservation);
        }

        private static ReservationResponse MapToResponse(Reservation reservation)
        {
            return new ReservationResponse
            {
                Id = reservation.Id,
                ActivityId = reservation.ActivityId,
                ActivityName = reservation.Activity?.Name ?? string.Empty,
                ActivityDateTime = reservation.Activity?.DateTime ?? default,
                UserId = reservation.UserId,
                UserName = reservation.User is null ? string.Empty : $"{reservation.User.FirstName} {reservation.User.LastName}",
                UserProfileImageUrl = reservation.User?.ProfileImageUrl,
                Status = reservation.Status.ToString(),
                CreatedAt = reservation.CreatedAt,
                ConfirmedAt = reservation.ConfirmedAt,
                CompletedAt = reservation.CompletedAt,
                CancellationReason = reservation.CancellationReason,
                CancelledAt = reservation.CancelledAt,
                Payment = reservation.Payment is null ? null : new PaymentInfoResponse
                {
                    Id = reservation.Payment.Id,
                    Amount = reservation.Payment.Amount,
                    Status = reservation.Payment.Status.ToString(),
                    ClientSecret = null,
                    PaidAt = reservation.Payment.PaidAt,
                    RefundedAt = reservation.Payment.RefundedAt
                }
            };
        }
    }
}