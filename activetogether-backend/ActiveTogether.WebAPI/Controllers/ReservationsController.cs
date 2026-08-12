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
    [Authorize]
    public class ReservationsController : ControllerBase
    {
        private readonly IReservationService _service;

        public ReservationsController(IReservationService service)
        {
            _service = service;
        }

        [HttpGet]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetAll([FromQuery] ReservationSearchObject search)
        {
            return Ok(await _service.GetAllAsync(search));
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMy([FromQuery] ReservationSearchObject search)
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.GetMyReservationsAsync(userId, search));
        }

        [HttpGet("activity/{activityId}")]
        [Authorize(Roles = Roles.Organizer + "," + Roles.Admin)]
        public async Task<IActionResult> GetForActivity(int activityId, [FromQuery] ReservationSearchObject search)
        {
            var userId = GetCurrentUserId();
            var isAdmin = User.IsInRole(Roles.Admin);
            return Ok(await _service.GetForActivityAsync(activityId, search, userId, isAdmin));
        }

        [HttpPost]
        [Authorize(Roles = Roles.User + "," + Roles.Organizer)]
        public async Task<IActionResult> Create([FromBody] ReservationCreateRequest request)
        {
            var userId = GetCurrentUserId();
            var result = await _service.CreateAsync(request, userId);
            return Ok(result);
        }

        [HttpPut("{id}/confirm")]
        [Authorize(Roles = Roles.Organizer + "," + Roles.Admin)]
        public async Task<IActionResult> Confirm(int id)
        {
            var userId = GetCurrentUserId();
            var isAdmin = User.IsInRole(Roles.Admin);
            return Ok(await _service.ConfirmAsync(id, userId, isAdmin));
        }

        [HttpPut("{id}/complete")]
        [Authorize(Roles = Roles.Organizer + "," + Roles.Admin)]
        public async Task<IActionResult> Complete(int id)
        {
            var userId = GetCurrentUserId();
            var isAdmin = User.IsInRole(Roles.Admin);
            return Ok(await _service.CompleteAsync(id, userId, isAdmin));
        }

        [HttpPut("{id}/cancel")]
        public async Task<IActionResult> Cancel(int id, [FromBody] ReservationCancelRequest request)
        {
            var userId = GetCurrentUserId();
            var isAdmin = User.IsInRole(Roles.Admin);
            return Ok(await _service.CancelAsync(id, request, userId, isAdmin));
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("Token ne sadrži validan identifikator korisnika.");
            return int.Parse(idClaim);
        }
    }
}