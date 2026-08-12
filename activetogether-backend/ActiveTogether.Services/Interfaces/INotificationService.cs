using ActiveTogether.Model.Enums;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface INotificationService
    {
        Task NotifyAsync(int userId, NotificationType type, string title, string text);
        Task<PagedResult<NotificationResponse>> GetMyNotificationsAsync(int userId, NotificationSearchObject search);
        Task<int> GetUnreadCountAsync(int userId);
        Task MarkAsReadAsync(int id, int userId);
        Task MarkAllAsReadAsync(int userId);
    }
}