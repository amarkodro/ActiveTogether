using ActiveTogether.Model.Constants;
using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Messaging;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using ActiveTogether.Services.Messaging;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace ActiveTogether.Services.Services
{
    public class AuthService : IAuthService
    {
        private readonly ActiveTogetherDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IRabbitMqPublisher _publisher;

        public AuthService(ActiveTogetherDbContext context, IConfiguration configuration, IRabbitMqPublisher publisher)
        {
            _context = context;
            _configuration = configuration;
            _publisher = publisher;
        }

        public async Task<UserResponse> RegisterAsync(RegisterRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new BusinessException("Korisničko ime je već zauzeto.");

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new BusinessException("Email je već registrovan.");

            if (request.CityId.HasValue && !await _context.Cities.AnyAsync(c => c.Id == request.CityId.Value))
                throw new NotFoundException($"Grad sa Id {request.CityId} ne postoji.");

            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Username = request.Username,
                Email = request.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                PhoneNumber = request.PhoneNumber,
                CityId = request.CityId,
                Role = Roles.User,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        public async Task<LoginResponse> LoginAsync(LoginRequest request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == request.Username);

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new UnauthorizedAccessException("Pogrešno korisničko ime ili lozinka.");

            if (!user.IsActive)
                throw new UnauthorizedAccessException("Korisnički nalog je blokiran.");

            user.LastLoginAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            var (accessToken, expiresAt) = GenerateAccessToken(user);
            var refreshToken = GenerateRefreshToken();

            _context.RefreshTokens.Add(new RefreshToken
            {
                UserId = user.Id,
                Token = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                IsRevoked = false,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            return new LoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = expiresAt,
                User = MapToResponse(user)
            };
        }

        private (string token, DateTime expiresAt) GenerateAccessToken(User user)
        {
            var jwtKey = _configuration["Jwt:Key"]
                ?? throw new InvalidOperationException("Jwt:Key nije postavljen u .env fajlu.");
            var jwtIssuer = _configuration["Jwt:Issuer"];
            var jwtAudience = _configuration["Jwt:Audience"];

            var claims = new List<Claim>
            {
                new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Name, user.Username),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Role, user.Role)
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var expiresAt = DateTime.UtcNow.AddHours(2);

            var token = new JwtSecurityToken(
                issuer: jwtIssuer,
                audience: jwtAudience,
                claims: claims,
                expires: expiresAt,
                signingCredentials: credentials);

            return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
        }

        private static string GenerateRefreshToken()
        {
            var bytes = RandomNumberGenerator.GetBytes(64);
            return Convert.ToBase64String(bytes);
        }

        private static UserResponse MapToResponse(User user)
        {
            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Username = user.Username,
                Email = user.Email,
                Role = user.Role,
                ProfileImageUrl = user.ProfileImageUrl
            };
        }

        public async Task<LoginResponse> RefreshTokenAsync(string refreshToken)
        {
            var token = await _context.RefreshTokens
                .Include(rt => rt.User)
                .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

            if (token is null || token.IsRevoked || token.ExpiresAt <= DateTime.UtcNow)
                throw new UnauthorizedAccessException("Refresh token nije validan ili je istekao.");

            if (!token.User!.IsActive)
                throw new UnauthorizedAccessException("Korisnički nalog je blokiran.");

            token.IsRevoked = true;

            var (accessToken, expiresAt) = GenerateAccessToken(token.User!);
            var newRefreshToken = GenerateRefreshToken();

            _context.RefreshTokens.Add(new RefreshToken
            {
                UserId = token.UserId,
                Token = newRefreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                IsRevoked = false,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return new LoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = newRefreshToken,
                ExpiresAt = expiresAt,
                User = MapToResponse(token.User!)
            };
        }

        public async Task LogoutAsync(string refreshToken)
        {
            var token = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

            if (token is null)
                return;

            token.IsRevoked = true;
            await _context.SaveChangesAsync();
        }

        public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user is null)
                return; // ne otkrivamo da li email postoji u sistemu

            var code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();

            _context.PasswordResetTokens.Add(new PasswordResetToken
            {
                UserId = user.Id,
                Code = code,
                ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                IsUsed = false,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            try
            {
                await _publisher.PublishEmailNotificationAsync(new EmailNotificationMessage
                {
                    ToEmail = user.Email,
                    ToName = $"{user.FirstName} {user.LastName}",
                    Subject = "Reset lozinke - ActiveTogether",
                    Body = $"Vaš kod za reset lozinke je: {code}\n\nKod važi 15 minuta. Ako niste vi tražili reset lozinke, slobodno ignorišite ovaj email."
                });
            }
            catch (Exception)
            {
                // Ako RabbitMQ nije dostupan, ne rušimo zahtjev - kod je ipak sačuvan u bazi.
            }
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var token = await _context.PasswordResetTokens
                .Include(t => t.User)
                .Where(t => t.Code == request.Code
                    && t.User!.Email == request.Email
                    && !t.IsUsed
                    && t.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(t => t.CreatedAt)
                .FirstOrDefaultAsync()
                ?? throw new BusinessException("Kod je nevažeći ili je istekao.");

            token.User!.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            token.IsUsed = true;

            await _context.SaveChangesAsync();
        }
    }
}