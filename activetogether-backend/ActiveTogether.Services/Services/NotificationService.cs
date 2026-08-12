using ActiveTogether.Model.Enums;
using ActiveTogether.Model.Messaging;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using ActiveTogether.Services.Messaging;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly ActiveTogetherDbContext _context;
        private readonly IHubContext<NotificationsHub> _hubContext;
        private readonly IRabbitMqPublisher _publisher;

        public NotificationService(ActiveTogetherDbContext context, IHubContext<NotificationsHub> hubContext, IRabbitMqPublisher publisher)
        {
            _context = context;
            _hubContext = hubContext;
            _publisher = publisher;
        }

        public async Task NotifyAsync(int userId, NotificationType type, string title, string text)
        {
            var notification = new Notification
            {
                UserId = userId,
                Type = type,
                Title = title,
                Text = text,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            await _hubContext.Clients.Group(NotificationsHub.GroupName(userId.ToString()))
                .SendAsync("ReceiveNotification", new
                {
                    notification.Id,
                    Type = notification.Type.ToString(),
                    notification.Title,
                    notification.Text,
                    notification.CreatedAt
                });

            var user = await _context.Users.FindAsync(userId);
            if (user is not null)
            {
                await _publisher.PublishEmailNotificationAsync(new EmailNotificationMessage
                {
                    ToEmail = user.Email,
                    ToName = $"{user.FirstName} {user.LastName}",
                    Subject = title,
                    Body = text
                });
            }
        }

        private const int MaxPageSize = 100;

        public async Task<PagedResult<NotificationResponse>> GetMyNotificationsAsync(int userId, NotificationSearchObject search)
        {
            var query = _context.Notifications.Where(n => n.UserId == userId).AsQueryable();

            if (search.IsRead.HasValue)
                query = query.Where(n => n.IsRead == search.IsRead.Value);

            var totalCount = await query.CountAsync();

            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var notifications = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NotificationResponse
                {
                    Id = n.Id,
                    Type = n.Type.ToString(),
                    Title = n.Title,
                    Text = n.Text,
                    IsRead = n.IsRead,
                    CreatedAt = n.CreatedAt
                })
                .ToListAsync();

            return new PagedResult<NotificationResponse>
            {
                Items = notifications,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            return await _context.Notifications.CountAsync(n => n.UserId == userId && !n.IsRead);
        }

        public async Task MarkAsReadAsync(int id, int userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

            if (notification is null || notification.IsRead)
                return;

            notification.IsRead = true;
            await _context.SaveChangesAsync();
        }

        public async Task MarkAllAsReadAsync(int userId)
        {
            await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ExecuteUpdateAsync(setters => setters.SetProperty(n => n.IsRead, true));
        }
    }
}