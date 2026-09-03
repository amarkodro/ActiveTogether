using ActiveTogether.Model.Constants;
using ActiveTogether.Model.Exceptions;
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
        /// Upload slike aktivnosti je dozvoljen samo Organizatoru/Adminu; upload profilne
        /// slike je vezan za prijavljenog korisnika i njegov vlastiti profil.
        /// </summary>
        [HttpPost("upload")]
        public async Task<IActionResult> Upload(IFormFile file, [FromQuery] string type = "profile")
        {
            if (type != "profile" && type != "activity")
                throw new BusinessException("Nepoznat tip otpremanja slike.");

            if (type == "activity" && !User.IsInRole(Roles.Organizer) && !User.IsInRole(Roles.Admin))
                throw new BusinessException("Samo organizator ili admin mogu otpremiti sliku aktivnosti.");

            var url = await _fileUploadService.UploadImageAsync(file, type);
            return Ok(new { url });
        }
    }
}
