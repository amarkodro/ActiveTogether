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

            return new RatingResponse
            {
                Id = rating.Id,
                ReservationId = rating.ReservationId,
                ActivityId = rating.ActivityId,
                Score = rating.Score,
                Comment = rating.Comment,
                CreatedAt = rating.CreatedAt
            };
        }
    }
}