using ActiveTogether.Model.Constants;
using ActiveTogether.Model.Enums;
using ActiveTogether.Model.Requests;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.WebAPI.BackgroundServices
{
    /// <summary>
    /// Pozadinski servis koji generiše notifikacije za koje ne postoji jedan konkretan
    /// CRUD/event trigger u kontroleru/servisu, nego zavise od proteka vremena:
    ///
    /// 1. NotificationType.ActivityReminder - podsjetnik učesnicima sa potvrđenom
    ///    rezervacijom, otprilike sat vremena prije početka aktivnosti.
    /// 2. NotificationType.Recommendation - jednom dnevno po korisniku, na osnovu
    ///    postojećeg (nepromijenjenog) hibridnog algoritma iz RecommendationService.
    ///
    /// Postojeći SignalR/read-unread kanal (NotificationService.NotifyAsync) se ovdje
    /// samo poziva kao isporuka - isti kod koji već koriste svi ostali eventi
    /// (rezervacija, potvrda, otkazivanje, plaćanje...).
    /// </summary>
    public class NotificationTriggersBackgroundService : BackgroundService
    {
        private static readonly TimeSpan PollInterval = TimeSpan.FromMinutes(5);
        private static readonly TimeSpan ReminderLeadTime = TimeSpan.FromHours(1);

        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<NotificationTriggersBackgroundService> _logger;

        public NotificationTriggersBackgroundService(
            IServiceScopeFactory scopeFactory,
            ILogger<NotificationTriggersBackgroundService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            using var timer = new PeriodicTimer(PollInterval);

            do
            {
                try
                {
                    await SendActivityRemindersAsync(stoppingToken);
                    await SendDailyRecommendationsAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška u NotificationTriggersBackgroundService ciklusu.");
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }

        private async Task SendActivityRemindersAsync(CancellationToken ct)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ActiveTogetherDbContext>();
            var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

            var now = DateTime.UtcNow;
            // Prozor je širok tačno koliko i interval provjere, tako da se svaka
            // rezervacija uhvati tačno jednom (bez preklapanja i bez rupa), a
            // ReminderSentAt dodatno štiti od duplog slanja nakon restarta servisa.
            var windowStart = now.Add(ReminderLeadTime);
            var windowEnd = windowStart.Add(PollInterval);

            var reservations = await context.Reservations
                .Include(r => r.Activity)
                .Where(r => r.Status == ReservationStatus.Confirmed
                    && r.ReminderSentAt == null
                    && r.Activity != null
                    && r.Activity.Status == ActivityStatus.Active
                    && r.Activity.DateTime >= windowStart
                    && r.Activity.DateTime < windowEnd)
                .ToListAsync(ct);

            if (reservations.Count == 0)
                return;

            foreach (var reservation in reservations)
            {
                reservation.ReminderSentAt = now;

                await notificationService.NotifyAsync(
                    reservation.UserId,
                    NotificationType.ActivityReminder,
                    "Podsjetnik o aktivnosti",
                    $"Aktivnost \"{reservation.Activity!.Name}\" počinje uskoro. Ne zaboravi!");
            }

            await context.SaveChangesAsync(ct);

            _logger.LogInformation("Poslano {Count} ActivityReminder notifikacija.", reservations.Count);
        }

        private async Task SendDailyRecommendationsAsync(CancellationToken ct)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ActiveTogetherDbContext>();
            var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
            var recommendationService = scope.ServiceProvider.GetRequiredService<IRecommendationService>();

            var today = DateTime.UtcNow.Date;

            var userIds = await context.Users
                .Where(u => u.IsActive && (u.Role == Roles.User || u.Role == Roles.Organizer))
                .Select(u => u.Id)
                .ToListAsync(ct);

            var sentCount = 0;

            foreach (var userId in userIds)
            {
                // Najviše jedna Recommendation notifikacija dnevno po korisniku -
                // provjera je bazirana na bazi (ne na in-memory stanju), pa je
                // otporna na restart servisa u toku dana.
                var alreadyNotifiedToday = await context.Notifications.AnyAsync(
                    n => n.UserId == userId
                        && n.Type == NotificationType.Recommendation
                        && n.CreatedAt >= today,
                    ct);

                if (alreadyNotifiedToday)
                    continue;

                var recommendations = await recommendationService.GetRecommendationsAsync(
                    userId,
                    new RecommendationSearchObject { Page = 1, PageSize = 1 });

                var top = recommendations.Items.FirstOrDefault();
                if (top == null)
                    continue;

                await notificationService.NotifyAsync(
                    userId,
                    NotificationType.Recommendation,
                    "Preporuka za tebe",
                    $"\"{top.Activity.Name}\" bi ti se moglo svidjeti - {top.Reason}.");

                sentCount++;
            }

            if (sentCount > 0)
                _logger.LogInformation("Poslano {Count} Recommendation notifikacija.", sentCount);
        }
    }
}
