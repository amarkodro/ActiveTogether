using ActiveTogether.Model.Constants;
using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ActiveTogether.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = Roles.Admin)]
    public class ReportsController : ControllerBase
    {
        private readonly IReportService _service;

        public ReportsController(IReportService service)
        {
            _service = service;
        }

        [HttpGet("activity-popularity")]
        public async Task<IActionResult> ActivityPopularity([FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo)
        {
            var pdf = await _service.GenerateActivityPopularityReportAsync(dateFrom, dateTo);
            return File(pdf, "application/pdf", "popularnost-aktivnosti.pdf");
        }

        [HttpGet("user-activity")]
        public async Task<IActionResult> UserActivity([FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo)
        {
            var pdf = await _service.GenerateUserActivityReportAsync(dateFrom, dateTo);
            return File(pdf, "application/pdf", "aktivnost-korisnika.pdf");
        }
    }
}