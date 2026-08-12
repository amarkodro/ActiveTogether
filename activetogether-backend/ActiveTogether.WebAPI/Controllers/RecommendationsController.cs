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
    public class RecommendationsController : ControllerBase
    {
        private readonly IRecommendationService _service;

        public RecommendationsController(IRecommendationService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetRecommendations([FromQuery] RecommendationSearchObject search)
        {
            var userId = GetCurrentUserId();
            return Ok(await _service.GetRecommendationsAsync(userId, search));
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("Token ne sadrži validan identifikator korisnika.");
            return int.Parse(idClaim);
        }
    }
}