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
    public class RatingService : IRatingService
    {
        private readonly ActiveTogetherDbContext _context;

        public RatingService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<RatingResponse> CreateAsync(RatingCreateRequest request, int userId)
        {
            var reservation = await _context.Reservations.FindAsync(request.ReservationId)
                ?? throw new NotFoundException("Rezervacija ne postoji.");

            if (reservation.UserId != userId)
                throw new BusinessException("Nemate dozvolu da ocijenite ovu rezervaciju.");

            if (reservation.Status != ReservationStatus.Completed)
                throw new BusinessException("Možete ocijeniti samo aktivnosti sa statusom Završeno.");

            var alreadyRated = await _context.Ratings.AnyAsync(r => r.ReservationId == request.ReservationId);
            if (alreadyRated)
                throw new BusinessException("Već ste ocijenili ovu aktivnost.");

            var rating = new Rating
            {
                ReservationId = request.ReservationId,
                UserId = userId,
                ActivityId = reservation.ActivityId,
                Score = request.Score,
                Comment = request.Comment,
                CreatedAt = DateTime.UtcNow
            };

            _context.Ratings.Add(rating);
            await _context.SaveChangesAsync();

            var user = await _context.Users.FindAsync(userId);

            return new RatingResponse
            {
                Id = rating.Id,
                ReservationId = rating.ReservationId,
                ActivityId = rating.ActivityId,
                UserId = rating.UserId,
                UserName = user is null ? string.Empty : $"{user.FirstName} {user.LastName}",
                UserProfileImageUrl = user?.ProfileImageUrl,
                Score = rating.Score,
                Comment = rating.Comment,
                CreatedAt = rating.CreatedAt
            };
        }

        public async Task<List<RatingResponse>> GetForActivityAsync(int activityId)
        {
            return await _context.Ratings
                .Include(r => r.User)
                .Where(r => r.ActivityId == activityId)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new RatingResponse
                {
                    Id = r.Id,
                    ReservationId = r.ReservationId,
                    ActivityId = r.ActivityId,
                    UserId = r.UserId,
                    UserName = r.User == null ? string.Empty : r.User.FirstName + " " + r.User.LastName,
                    UserProfileImageUrl = r.User != null ? r.User.ProfileImageUrl : null,
                    Score = r.Score,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt
                })
                .ToListAsync();
        }
    }
}