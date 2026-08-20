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
    public class ProfileController : ControllerBase
    {
        private readonly IProfileService _service;

        public ProfileController(IProfileService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetMy()
        {
            return Ok(await _service.GetMyProfileAsync(GetCurrentUserId()));
        }

        [HttpPut]
        public async Task<IActionResult> UpdateMy([FromBody] ProfileUpdateRequest request)
        {
            return Ok(await _service.UpdateMyProfileAsync(GetCurrentUserId(), request));
        }

        [HttpPut("password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            await _service.ChangePasswordAsync(GetCurrentUserId(), request);
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