using ActiveTogether.Model.Exceptions;
using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace ActiveTogether.Services.Services
{
    public class FileUploadService : IFileUploadService
    {
        private const long MaxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

        private static readonly HashSet<string> AllowedExtensions = new()
        {
            ".jpg", ".jpeg", ".png", ".webp"
        };

        private static readonly Dictionary<string, string[]> AllowedContentTypesByExtension = new()
        {
            [".jpg"] = new[] { "image/jpeg" },
            [".jpeg"] = new[] { "image/jpeg" },
            [".png"] = new[] { "image/png" },
            [".webp"] = new[] { "image/webp" }
        };

        private readonly IWebHostEnvironment _env;

        public FileUploadService(IWebHostEnvironment env)
        {
            _env = env;
        }

        public async Task<string> UploadImageAsync(IFormFile? file, string category)
        {
            if (file == null || file.Length == 0)
                throw new BusinessException("Fajl nije poslan.");

            if (file.Length > MaxFileSizeBytes)
                throw new BusinessException("Slika je prevelika (maksimalno 5MB).");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!AllowedExtensions.Contains(extension))
                throw new BusinessException("Dozvoljeni formati slike su: JPG, PNG, WEBP.");

            var contentType = file.ContentType?.Trim().ToLowerInvariant() ?? string.Empty;
            if (!AllowedContentTypesByExtension.TryGetValue(extension, out var allowedContentTypes) ||
                !allowedContentTypes.Contains(contentType))
                throw new BusinessException("Deklarisani tip fajla (Content-Type) nije dozvoljen za sliku.");

            byte[] bytes;
            using (var memoryStream = new MemoryStream())
            {
                await file.CopyToAsync(memoryStream);
                bytes = memoryStream.ToArray();
            }

            if (!IsValidImageSignature(bytes, extension))
                throw new BusinessException("Sadržaj fajla ne odgovara deklarisanom formatu slike.");

            var folder = category == "profile" ? "profiles" : "activities";
            var uploadsRoot = Path.Combine(_env.ContentRootPath, "wwwroot", "uploads", folder);
            Directory.CreateDirectory(uploadsRoot);

            var fileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploadsRoot, fileName);

            await File.WriteAllBytesAsync(filePath, bytes);

            return $"/uploads/{folder}/{fileName}";
        }

        private static bool IsValidImageSignature(byte[] header, string extension)
        {
            if (extension is ".jpg" or ".jpeg")
                return header.Length >= 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;

            if (extension == ".png")
            {
                byte[] pngSignature = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };
                return header.Length >= 8 && header.Take(8).SequenceEqual(pngSignature);
            }

            if (extension == ".webp")
            {
                return header.Length >= 12 &&
                    header[0] == (byte)'R' && header[1] == (byte)'I' && header[2] == (byte)'F' && header[3] == (byte)'F' &&
                    header[8] == (byte)'W' && header[9] == (byte)'E' && header[10] == (byte)'B' && header[11] == (byte)'P';
            }

            return false;
        }
    }
}
