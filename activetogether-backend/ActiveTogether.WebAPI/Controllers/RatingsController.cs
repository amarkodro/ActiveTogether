using ActiveTogether.Model.Constants;
using ActiveTogether.Model.Requests;
using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace ActiveTogether.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = Roles.User + "," + Roles.Organizer)]
    public class RatingsController : ControllerBase
    {
        private readonly IRatingService _service;

        public RatingsController(IRatingService service)
        {
            _service = service;
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] RatingCreateRequest request)
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.CreateAsync(request, userId));
        }

        /// <summary>
        /// Ocjene i komentari za aktivnost - javno dostupno (isto kao i detalji same
        /// aktivnosti), da komentar ne ostane write-only podatak vidljiv samo autoru.
        /// </summary>
        [HttpGet("activity/{activityId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetForActivity(int activityId)
        {
            return Ok(await _service.GetForActivityAsync(activityId));
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("Token ne sadrži validan identifikator korisnika.");
            return int.Parse(idClaim);
        }
    }
}