using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class UserService : IUserService
    {
        private const int MaxPageSize = 100;

        private readonly ActiveTogetherDbContext _context;

        public UserService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<UserListResponse>> GetAllAsync(UserSearchObject search)
        {
            var query = _context.Users
                .Include(u => u.City)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(u =>
                    (u.FirstName + " " + u.LastName).Contains(search.Name) ||
                    u.Email.Contains(search.Name));

            if (!string.IsNullOrWhiteSpace(search.Email))
                query = query.Where(u => u.Email.Contains(search.Email));

            if (!string.IsNullOrWhiteSpace(search.Role))
                query = query.Where(u => u.Role == search.Role);

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            var totalCount = await query.CountAsync();

            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var items = await query
                .OrderByDescending(u => u.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(u => MapToResponse(u))
                .ToListAsync();

            return new PagedResult<UserListResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<UserListResponse> GetByIdAsync(int id)
        {
            var user = await _context.Users
                .Include(u => u.City)
                .FirstOrDefaultAsync(u => u.Id == id)
                ?? throw new NotFoundException($"Korisnik sa Id {id} ne postoji.");

            return MapToResponse(user);
        }

        public async Task<UserListResponse> UpdateAsync(int id, UserUpdateRequest request)
        {
            var user = await _context.Users
                .Include(u => u.City)
                .FirstOrDefaultAsync(u => u.Id == id)
                ?? throw new NotFoundException($"Korisnik sa Id {id} ne postoji.");

            var emailTaken = await _context.Users
                .AnyAsync(u => u.Id != id && u.Email == request.Email);

            if (emailTaken)
                throw new BusinessException("Email adresa je već u upotrebi.");

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.Email = request.Email;
            user.PhoneNumber = request.PhoneNumber;
            user.CityId = request.CityId;
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await _context.Entry(user).Reference(u => u.City).LoadAsync();

            return MapToResponse(user);
        }

        public async Task SetActiveStatusAsync(int id, bool isActive)
        {
            var user = await _context.Users.FindAsync(id)
                ?? throw new NotFoundException($"Korisnik sa Id {id} ne postoji.");

            user.IsActive = isActive;
            user.UpdatedAt = DateTime.UtcNow;

            if (!isActive)
            {
                // Blokiranje naloga mora prekinuti i već otvorenu sesiju - u suprotnom
                // korisnik i dalje može refreshovati access token dok mu refresh token važi.
                await _context.RefreshTokens
                    .Where(rt => rt.UserId == id && !rt.IsRevoked)
                    .ExecuteUpdateAsync(setters => setters.SetProperty(rt => rt.IsRevoked, true));
            }

            await _context.SaveChangesAsync();
        }

        private static UserListResponse MapToResponse(Database.Entities.User user)
        {
            return new UserListResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Role = user.Role,
                IsActive = user.IsActive,
                CityName = user.City != null ? user.City.Name : null,
                ProfileImageUrl = user.ProfileImageUrl,
                CreatedAt = user.CreatedAt
            };
        }
    }
}