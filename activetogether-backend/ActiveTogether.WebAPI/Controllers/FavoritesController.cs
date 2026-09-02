using ActiveTogether.Model.Constants;
using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace ActiveTogether.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = Roles.User + "," + Roles.Organizer)]
    public class FavoritesController : ControllerBase
    {
        private readonly IFavoriteService _service;

        public FavoritesController(IFavoriteService service)
        {
            _service = service;
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMy([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.GetMyFavoritesAsync(userId, page, pageSize));
        }

        [HttpGet("{activityId}/status")]
        public async Task<IActionResult> GetStatus(int activityId)
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.IsFavoriteAsync(userId, activityId));
        }

        [HttpPost("{activityId}")]
        public async Task<IActionResult> Add(int activityId)
        {
            var userId = GetCurrentUserId();
            await _service.AddAsync(userId, activityId);
            return NoContent();
        }

        [HttpDelete("{activityId}")]
        public async Task<IActionResult> Remove(int activityId)
        {
            var userId = GetCurrentUserId();
            await _service.RemoveAsync(userId, activityId);
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
