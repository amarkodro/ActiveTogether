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

            await SeedTestUserIfMissingAsync(context, "desktop", "Desktop", "Test", "desktop@activetogether.com", Roles.Admin);
            await SeedTestUserIfMissingAsync(context, "mobile", "Mobile", "Test", "mobile@activetogether.com", Roles.User);
            await SeedTestUserIfMissingAsync(context, "organizator", "Organizator", "Test", "organizator@activetogether.com", Roles.Organizer);
        }

        private static async Task SeedTestUserIfMissingAsync(
            ActiveTogetherDbContext context,
            string username,
            string firstName,
            string lastName,
            string email,
            string role)
        {
            if (await context.Users.AnyAsync(u => u.Username == username))
                return;

            var user = new User
            {
                FirstName = firstName,
                LastName = lastName,
                Username = username,
                Email = email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                Role = role,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Users.Add(user);
            await context.SaveChangesAsync();
        }
    }
}