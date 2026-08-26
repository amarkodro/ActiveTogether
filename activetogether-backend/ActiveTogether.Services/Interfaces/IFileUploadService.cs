using Microsoft.AspNetCore.Http;

namespace ActiveTogether.Services.Interfaces
{
    public interface IFileUploadService
    {
        Task<string> UploadImageAsync(IFormFile? file, string category);
    }
}
