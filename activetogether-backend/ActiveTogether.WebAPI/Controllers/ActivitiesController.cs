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
    public class ActivitiesController : ControllerBase
    {
        private readonly IActivityService _service;


        public ActivitiesController(IActivityService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] ActivitySearchObject search)
        {
            var isAdmin = User.IsInRole(Roles.Admin);
            var result = await _service.GetAllAsync(search, organizerId: null, includeAllStatuses: isAdmin, GetCurrentUserIdOrNull());
            return Ok(result);
        }

        [HttpGet("my")]
        [Authorize(Roles = Roles.Organizer)]
        public async Task<IActionResult> GetMyActivities([FromQuery] ActivitySearchObject search)
        {
            var organizerId = GetCurrentUserId();
            var result = await _service.GetAllAsync(search, organizerId, includeAllStatuses: true, currentUserId: null);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            return Ok(await _service.GetByIdAsync(id, GetCurrentUserIdOrNull()));
        }

        [HttpPost]
        [Authorize(Roles = Roles.Organizer)]
        public async Task<IActionResult> Create([FromBody] ActivityUpsertRequest request)
        {
            var organizerId = GetCurrentUserId();
            var result = await _service.CreateAsync(request, organizerId);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = Roles.Organizer + "," + Roles.Admin)]
        public async Task<IActionResult> Update(int id, [FromBody] ActivityUpsertRequest request)
        {
            var userId = GetCurrentUserId();
            var isAdmin = User.IsInRole(Roles.Admin);
            return Ok(await _service.UpdateAsync(id, request, userId, isAdmin));
        }

        [HttpPut("{id}/cancel")]
        [Authorize(Roles = Roles.Organizer + "," + Roles.Admin)]
        public async Task<IActionResult> Cancel(int id)
        {
            var userId = GetCurrentUserId();
            var isAdmin = User.IsInRole(Roles.Admin);
            return Ok(await _service.CancelAsync(id, userId, isAdmin));
        }

        [HttpPut("{id}/complete")]
        [Authorize(Roles = Roles.Organizer + "," + Roles.Admin)]
        public async Task<IActionResult> Complete(int id)
        {
            var userId = GetCurrentUserId();
            var isAdmin = User.IsInRole(Roles.Admin);
            return Ok(await _service.CompleteAsync(id, userId, isAdmin));
        }

        private int? GetCurrentUserIdOrNull()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return idClaim is null ? null : int.Parse(idClaim);
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("Token ne sadrži validan identifikator korisnika.");
            return int.Parse(idClaim);
        }
    }
}