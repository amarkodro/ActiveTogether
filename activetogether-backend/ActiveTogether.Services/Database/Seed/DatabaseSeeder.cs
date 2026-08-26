using ActiveTogether.Model.Constants;
using ActiveTogether.Model.Enums;
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

            var referenceData = await SeedReferenceDataAsync(context);

            var organizer = await context.Users.FirstAsync(u => u.Username == "organizator");
            var mobileUser = await context.Users.FirstAsync(u => u.Username == "mobile");

            await SeedActivitiesAsync(context, referenceData, organizer.Id, mobileUser.Id);
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

        private class ReferenceData
        {
            public City Sarajevo = null!;
            public City Mostar = null!;
            public Category Sport = null!;
            public Category Fitness = null!;
            public Category Outdoor = null!;
            public ActivityType Trening = null!;
            public ActivityType Utakmica = null!;
            public ActivityType Izlet = null!;
            public Location GradskiParkSarajevo = null!;
            public Location SjeverniLogorMostar = null!;
            public Location GradskiStadionMostar = null!;
        }

        private static async Task<Country> EnsureCountryAsync(ActiveTogetherDbContext context, string name)
        {
            var existing = await context.Countries.FirstOrDefaultAsync(c => c.Name == name);
            if (existing != null) return existing;

            var created = new Country { Name = name };
            context.Countries.Add(created);
            await context.SaveChangesAsync();
            return created;
        }

        private static async Task<City> EnsureCityAsync(ActiveTogetherDbContext context, string name, int countryId)
        {
            var existing = await context.Cities.FirstOrDefaultAsync(c => c.Name == name);
            if (existing != null) return existing;

            var created = new City { Name = name, CountryId = countryId };
            context.Cities.Add(created);
            await context.SaveChangesAsync();
            return created;
        }

        private static async Task<Category> EnsureCategoryAsync(ActiveTogetherDbContext context, string name)
        {
            var existing = await context.Categories.FirstOrDefaultAsync(c => c.Name == name);
            if (existing != null) return existing;

            var created = new Category { Name = name };
            context.Categories.Add(created);
            await context.SaveChangesAsync();
            return created;
        }

        private static async Task<ActivityType> EnsureActivityTypeAsync(ActiveTogetherDbContext context, string name)
        {
            var existing = await context.ActivityTypes.FirstOrDefaultAsync(t => t.Name == name);
            if (existing != null) return existing;

            var created = new ActivityType { Name = name };
            context.ActivityTypes.Add(created);
            await context.SaveChangesAsync();
            return created;
        }

        private static async Task<Location> EnsureLocationAsync(
            ActiveTogetherDbContext context, string name, string address, int cityId, double latitude, double longitude)
        {
            var existing = await context.Locations.FirstOrDefaultAsync(l => l.Name == name);
            if (existing != null) return existing;

            var created = new Location { Name = name, Address = address, CityId = cityId, Latitude = latitude, Longitude = longitude };
            context.Locations.Add(created);
            await context.SaveChangesAsync();
            return created;
        }

        private static async Task<ReferenceData> SeedReferenceDataAsync(ActiveTogetherDbContext context)
        {
            var country = await EnsureCountryAsync(context, "Bosna i Hercegovina");

            var sarajevo = await EnsureCityAsync(context, "Sarajevo", country.Id);
            var mostar = await EnsureCityAsync(context, "Mostar", country.Id);
            await EnsureCityAsync(context, "Banja Luka", country.Id);
            await EnsureCityAsync(context, "Tuzla", country.Id);

            var sport = await EnsureCategoryAsync(context, "Sport");
            var fitness = await EnsureCategoryAsync(context, "Fitness");
            var outdoor = await EnsureCategoryAsync(context, "Outdoor");

            var trening = await EnsureActivityTypeAsync(context, "Trening");
            var utakmica = await EnsureActivityTypeAsync(context, "Utakmica");
            var izlet = await EnsureActivityTypeAsync(context, "Izlet");
            await EnsureActivityTypeAsync(context, "Turnir");

            var gradskiParkSarajevo = await EnsureLocationAsync(
                context, "Gradski park", "Koševo bb", sarajevo.Id, 43.8610, 18.4108);
            var sjeverniLogorMostar = await EnsureLocationAsync(
                context, "Sjeverni logor", "Sjeverni Logor bb", mostar.Id, 43.3576, 17.8171);
            var gradskiStadionMostar = await EnsureLocationAsync(
                context, "Gradski stadion", "Sportska 1", mostar.Id, 43.3438, 17.8078);

            return new ReferenceData
            {
                Sarajevo = sarajevo,
                Mostar = mostar,
                Sport = sport,
                Fitness = fitness,
                Outdoor = outdoor,
                Trening = trening,
                Utakmica = utakmica,
                Izlet = izlet,
                GradskiParkSarajevo = gradskiParkSarajevo,
                SjeverniLogorMostar = sjeverniLogorMostar,
                GradskiStadionMostar = gradskiStadionMostar
            };
        }

        private static async Task SeedActivitiesAsync(
            ActiveTogetherDbContext context,
            ReferenceData refData,
            int organizerId,
            int mobileUserId)
        {
            if (await context.Activities.AnyAsync())
                return;

            var jutarnjaYoga = new Activity
            {
                Name = "Jutarnja yoga",
                Description = "Opuštajuća jutarnja yoga sesija za sve nivoe iskustva. Ponesite prostirku.",
                CategoryId = refData.Fitness.Id,
                ActivityTypeId = refData.Trening.Id,
                LocationId = refData.GradskiParkSarajevo.Id,
                OrganizerId = organizerId,
                DateTime = DateTime.UtcNow.AddDays(2).Date.AddHours(8),
                Capacity = 10,
                IsFree = true,
                Status = ActivityStatus.Active,
                CreatedAt = DateTime.UtcNow
            };

            var nogomet5v5 = new Activity
            {
                Name = "Nogomet 5v5",
                Description = "Prijateljski meč 5 na 5. Svi nivoi dobrodošli. Donesite vlastite kopačke.",
                CategoryId = refData.Sport.Id,
                ActivityTypeId = refData.Utakmica.Id,
                LocationId = refData.SjeverniLogorMostar.Id,
                OrganizerId = organizerId,
                DateTime = DateTime.UtcNow.AddDays(3).Date.AddHours(19),
                Capacity = 10,
                IsFree = false,
                Price = 10,
                Status = ActivityStatus.Active,
                CreatedAt = DateTime.UtcNow
            };

            var planinarenje = new Activity
            {
                Name = "Planinarenje Trebević",
                Description = "Poludnevni izlet na Trebević za sve ljubitelje planinarenja.",
                CategoryId = refData.Outdoor.Id,
                ActivityTypeId = refData.Izlet.Id,
                LocationId = refData.GradskiParkSarajevo.Id,
                OrganizerId = organizerId,
                DateTime = DateTime.UtcNow.AddDays(5).Date.AddHours(9),
                Capacity = 15,
                IsFree = true,
                Status = ActivityStatus.Active,
                CreatedAt = DateTime.UtcNow
            };

            var treningBoksa = new Activity
            {
                Name = "Trening boksa",
                Description = "Uvodni trening boksa za početnike. Oprema je obezbijeđena.",
                CategoryId = refData.Sport.Id,
                ActivityTypeId = refData.Trening.Id,
                LocationId = refData.GradskiStadionMostar.Id,
                OrganizerId = organizerId,
                DateTime = DateTime.UtcNow.AddDays(-3).Date.AddHours(18),
                Capacity = 8,
                IsFree = false,
                Price = 5,
                Status = ActivityStatus.Completed,
                CreatedAt = DateTime.UtcNow.AddDays(-10)
            };

            context.Activities.AddRange(jutarnjaYoga, nogomet5v5, planinarenje, treningBoksa);
            await context.SaveChangesAsync();

            var confirmedReservation = new Reservation
            {
                UserId = mobileUserId,
                ActivityId = jutarnjaYoga.Id,
                Status = ReservationStatus.Confirmed,
                CreatedAt = DateTime.UtcNow.AddDays(-1),
                ConfirmedAt = DateTime.UtcNow.AddDays(-1).AddMinutes(30)
            };

            var completedReservation = new Reservation
            {
                UserId = mobileUserId,
                ActivityId = treningBoksa.Id,
                Status = ReservationStatus.Completed,
                CreatedAt = DateTime.UtcNow.AddDays(-9),
                ConfirmedAt = DateTime.UtcNow.AddDays(-9).AddHours(1),
                CompletedAt = DateTime.UtcNow.AddDays(-3).AddHours(20)
            };

            context.Reservations.AddRange(confirmedReservation, completedReservation);
            await context.SaveChangesAsync();

            context.Payments.Add(new Payment
            {
                ReservationId = completedReservation.Id,
                Amount = treningBoksa.Price ?? 0,
                Status = PaymentStatus.Completed,
                StripePaymentIntentId = "seed_pi_demo",
                PaidAt = DateTime.UtcNow.AddDays(-9).AddHours(1),
                CreatedAt = DateTime.UtcNow.AddDays(-9)
            });
            await context.SaveChangesAsync();
        }
    }
}
