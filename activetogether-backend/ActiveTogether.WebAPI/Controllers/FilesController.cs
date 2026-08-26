using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ActiveTogether.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FilesController : ControllerBase
    {
        private readonly IFileUploadService _fileUploadService;

        public FilesController(IFileUploadService fileUploadService)
        {
            _fileUploadService = fileUploadService;
        }

        /// <summary>
        /// Otpremanje slike (profil ili aktivnost). Vraća relativni URL slike koji se
        /// zatim šalje kao ImageUrl/ProfileImageUrl uz odgovarajući update zahtjev.
        /// </summary>
        [HttpPost("upload")]
        public async Task<IActionResult> Upload(IFormFile file, [FromQuery] string type = "activity")
        {
            var url = await _fileUploadService.UploadImageAsync(file, type);
            return Ok(new { url });
        }
    }
}
