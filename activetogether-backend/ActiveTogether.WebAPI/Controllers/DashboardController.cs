using ActiveTogether.Model.Constants;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace ActiveTogether.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly IDashboardService _dashboardService;

        public DashboardController(IDashboardService dashboardService)
        {
            _dashboardService = dashboardService;
        }

        [HttpGet("admin")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<AdminDashboardResponse>> GetAdminDashboard()
        {
            var result = await _dashboardService.GetAdminDashboardAsync();
            return Ok(result);
        }

        [HttpGet("organizer")]
        [Authorize(Roles = Roles.Organizer)]
        public async Task<ActionResult<OrganizerDashboardResponse>> GetOrganizerDashboard()
        {
            var organizerId = int.Parse(User.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier)!);
            var result = await _dashboardService.GetOrganizerDashboardAsync(organizerId);
            return Ok(result);
        }
    }
}