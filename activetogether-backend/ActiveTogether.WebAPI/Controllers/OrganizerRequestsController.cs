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
    public class OrganizerRequestsController : ControllerBase
    {
        private readonly IOrganizerRequestService _service;

        public OrganizerRequestsController(IOrganizerRequestService service)
        {
            _service = service;
        }

        [HttpPost]
        [Authorize(Roles = Roles.User)]
        public async Task<IActionResult> Create()
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.CreateAsync(userId));
        }

        [HttpGet]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetAll([FromQuery] OrganizerRequestSearchObject search)
        {
            return Ok(await _service.GetAllAsync(search));
        }

        [HttpPut("{id}/approve")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Approve(int id)
        {
            var adminId = GetCurrentUserId();
            return Ok(await _service.ApproveAsync(id, adminId));
        }

        [HttpPut("{id}/reject")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Reject(int id, [FromBody] OrganizerRequestDecisionRequest request)
        {
            var adminId = GetCurrentUserId();
            return Ok(await _service.RejectAsync(id, adminId, request.Reason));
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("Token ne sadrži validan identifikator korisnika.");
            return int.Parse(idClaim);
        }
    }
}