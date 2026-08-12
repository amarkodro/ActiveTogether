using ActiveTogether.Model.Requests;
using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace ActiveTogether.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _service;

        public NotificationsController(INotificationService service)
        {
            _service = service;
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMy([FromQuery] NotificationSearchObject search)
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.GetMyNotificationsAsync(userId, search));
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.GetUnreadCountAsync(userId));
        }

        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userId = GetCurrentUserId();
            await _service.MarkAsReadAsync(id, userId);
            return NoContent();
        }

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = GetCurrentUserId();
            await _service.MarkAllAsReadAsync(userId);
            return NoContent();
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("Token ne sadrži validan identifikator korisnika.");
            return int.Parse(idClaim);
        }
    }
}