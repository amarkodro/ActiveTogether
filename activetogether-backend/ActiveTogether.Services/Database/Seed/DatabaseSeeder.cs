using ActiveTogether.Model.Constants;
using ActiveTogether.Services.Database.Entities;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Database.Seed
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAsync(ActiveTogetherDbContext context)
        {
            if (!await context.Users.AnyAsync(u => u.Role == Roles.Admin))
            {
                var admin = new User
                {
                    FirstName = "Admin",
                    LastName = "Administrator",
                    Username = "admin",
                    Email = "admin@activetogether.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                    Role = Roles.Admin,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };

                context.Users.Add(admin);
                await context.SaveChangesAsync();
            }
        }
    }
}