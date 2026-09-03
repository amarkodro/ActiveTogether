using ActiveTogether.Model.Constants;
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
    public class OrganizerRequestService : IOrganizerRequestService
    {
        private const int MaxPageSize = 100;

        private readonly ActiveTogetherDbContext _context;
        private readonly INotificationService _notificationService;

        public OrganizerRequestService(ActiveTogetherDbContext context, INotificationService notificationService)
        {
            _context = context;
            _notificationService = notificationService;
        }

        public async Task<OrganizerRequestResponse> CreateAsync(int userId)
        {
            var user = await _context.Users.FindAsync(userId)
                ?? throw new NotFoundException($"Korisnik sa Id {userId} ne postoji.");

            if (user.Role != Roles.User)
                throw new BusinessException("Samo korisnik sa ulogom Korisnik može poslati zahtjev za ulogu Organizatora.");

            var hasPending = await _context.OrganizerRequests
                .AnyAsync(r => r.UserId == userId && r.Status == OrganizerRequestStatus.Pending);

            if (hasPending)
                throw new BusinessException("Već postoji zahtjev na čekanju za ovog korisnika.");

            var request = new OrganizerRequest
            {
                UserId = userId,
                Status = OrganizerRequestStatus.Pending
            };

            _context.OrganizerRequests.Add(request);
            await _context.SaveChangesAsync();

            return await GetByIdWithMappingAsync(request.Id);
        }

        public async Task<PagedResult<OrganizerRequestResponse>> GetAllAsync(OrganizerRequestSearchObject search)
        {
            var query = _context.OrganizerRequests
                .Include(r => r.User)
                .AsQueryable();

            if (search.Status.HasValue)
                query = query.Where(r => r.Status == search.Status.Value);

            var totalCount = await query.CountAsync();

            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var items = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => MapToResponse(r))
                .ToListAsync();

            return new PagedResult<OrganizerRequestResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<OrganizerRequestResponse> ApproveAsync(int id, int adminId)
        {
            var request = await _context.OrganizerRequests
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Zahtjev sa Id {id} ne postoji.");

            if (request.Status != OrganizerRequestStatus.Pending)
                throw new BusinessException("Zahtjev je već obrađen.");

            request.Status = OrganizerRequestStatus.Approved;
            request.DecidedByUserId = adminId;
            request.DecidedAt = DateTime.UtcNow;
            request.User!.Role = Roles.Organizer;
            request.User.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.NotifyAsync(
                request.UserId,
                NotificationType.OrganizerRequestApproved,
                "Zahtjev odobren",
                "Vaš zahtjev za ulogu Organizatora je odobren. Sada možete kreirati aktivnosti.");

            return MapToResponse(request);
        }

        public async Task<OrganizerRequestResponse> RejectAsync(int id, int adminId, string? reason)
        {
            var request = await _context.OrganizerRequests
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Zahtjev sa Id {id} ne postoji.");

            if (request.Status != OrganizerRequestStatus.Pending)
                throw new BusinessException("Zahtjev je već obrađen.");

            if (string.IsNullOrWhiteSpace(reason))
                throw new BusinessException("Razlog odbijanja je obavezan.");

            request.Status = OrganizerRequestStatus.Rejected;
            request.RejectionReason = reason;
            request.DecidedByUserId = adminId;
            request.DecidedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _notificationService.NotifyAsync(
                request.UserId,
                NotificationType.OrganizerRequestRejected,
                "Zahtjev odbijen",
                $"Vaš zahtjev za ulogu Organizatora je odbijen. Razlog: {reason}");

            return MapToResponse(request);
        }

        private async Task<OrganizerRequestResponse> GetByIdWithMappingAsync(int id)
        {
            var request = await _context.OrganizerRequests
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Zahtjev sa Id {id} ne postoji.");

            return MapToResponse(request);
        }

        private static OrganizerRequestResponse MapToResponse(OrganizerRequest request)
        {
            return new OrganizerRequestResponse
            {
                Id = request.Id,
                UserId = request.UserId,
                UserFullName = request.User != null ? $"{request.User.FirstName} {request.User.LastName}" : string.Empty,
                UserEmail = request.User?.Email ?? string.Empty,
                UserProfileImageUrl = request.User?.ProfileImageUrl,
                Status = request.Status.ToString(),
                RejectionReason = request.RejectionReason,
                CreatedAt = request.CreatedAt,
                DecidedAt = request.DecidedAt
            };
        }
    }
}