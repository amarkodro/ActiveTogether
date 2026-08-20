using ActiveTogether.Model.Enums;
using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class ProfileService : IProfileService
    {
        private readonly ActiveTogetherDbContext _context;

        public ProfileService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<ProfileResponse> GetMyProfileAsync(int userId)
        {
            var user = await _context.Users
                .Include(u => u.City)
                .FirstOrDefaultAsync(u => u.Id == userId)
                ?? throw new NotFoundException("Korisnik ne postoji.");

            var totalReservations = await _context.Reservations
                .CountAsync(r => r.UserId == userId && r.Status != ReservationStatus.Cancelled);

            var completedCount = await _context.Reservations
                .CountAsync(r => r.UserId == userId && r.Status == ReservationStatus.Completed);

            var ratingsGiven = await _context.Ratings
                .Where(r => r.UserId == userId)
                .ToListAsync();

            return new ProfileResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Username = user.Username,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Role = user.Role,
                CityId = user.CityId,
                CityName = user.City?.Name,
                ProfileImageUrl = user.ProfileImageUrl,
                TotalReservations = totalReservations,
                CompletedActivitiesCount = completedCount,
                AverageRatingGiven = ratingsGiven.Count > 0 ? ratingsGiven.Average(r => r.Score) : (double?)null
            };
        }

        public async Task<ProfileResponse> UpdateMyProfileAsync(int userId, ProfileUpdateRequest request)
        {
            var user = await _context.Users.FindAsync(userId)
                ?? throw new NotFoundException("Korisnik ne postoji.");

            if (request.CityId.HasValue && !await _context.Cities.AnyAsync(c => c.Id == request.CityId.Value))
                throw new NotFoundException($"Grad sa Id {request.CityId} ne postoji.");

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.PhoneNumber = request.PhoneNumber;
            user.CityId = request.CityId;
            user.ProfileImageUrl = request.ProfileImageUrl;
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return await GetMyProfileAsync(userId);
        }

        public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
        {
            var user = await _context.Users.FindAsync(userId)
                ?? throw new NotFoundException("Korisnik ne postoji.");

            if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
                throw new BusinessException("Trenutna lozinka nije ispravna.");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }
    }
}