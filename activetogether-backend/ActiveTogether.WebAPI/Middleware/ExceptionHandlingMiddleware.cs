using ActiveTogether.Model.Exceptions;
using System.Net;
using System.Text.Json;

namespace ActiveTogether.WebAPI.Middleware
{
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionHandlingMiddleware> _logger;

        public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex);
            }
        }

        private async Task HandleExceptionAsync(HttpContext context, Exception ex)
        {
            var (statusCode, message) = ex switch
            {
                NotFoundException => (HttpStatusCode.NotFound, ex.Message),
                BusinessException => (HttpStatusCode.BadRequest, ex.Message),
                UnauthorizedAccessException => (HttpStatusCode.Unauthorized, ex.Message),
                _ => (HttpStatusCode.InternalServerError, "Došlo je do neočekivane greške. Pokušajte ponovo kasnije.")
            };

            if (statusCode == HttpStatusCode.InternalServerError)
                _logger.LogError(ex, "Neobrađena greška na {Path}", context.Request.Path);
            else
                _logger.LogWarning("{ExceptionType} na {Path}: {Message}", ex.GetType().Name, context.Request.Path, ex.Message);

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)statusCode;

            var result = JsonSerializer.Serialize(new { message });
            await context.Response.WriteAsync(result);
        }
    }
}