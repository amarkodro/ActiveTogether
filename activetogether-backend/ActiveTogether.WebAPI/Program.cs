using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Seed;
using ActiveTogether.Services.Interfaces;
using ActiveTogether.Services.Messaging;
using ActiveTogether.Services.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using System.Text;
using ActiveTogether.Services.Messaging;
using Microsoft.AspNetCore.Authentication.JwtBearer;

var envPath = Path.Combine(Directory.GetCurrentDirectory(), "..", ".env");
if (File.Exists(envPath))
{
    DotNetEnv.Env.Load(envPath);
}

QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

// wwwroot/uploads mora postojati PRIJE nego što se kreira WebApplicationBuilder,
// jer ASP.NET Core tada odlučuje da li static files provider uopšte postoji
// (ako foldera nema u tom trenutku, static fajlovi se nikad ne bi servirali,
// čak i kad se folder naknadno kreira dok app već radi).
Directory.CreateDirectory(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads"));

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Automatska [ApiController] model-state validacija (DataAnnotations) treba da vrati
// isti { message } oblik odgovora kao BusinessException, umjesto default ValidationProblemDetails
// formata, da bi Flutter strane (koje čitaju data['message']) mogle prikazati konkretnu grešku.
builder.Services.Configure<Microsoft.AspNetCore.Mvc.ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var message = string.Join(" ", context.ModelState.Values
            .SelectMany(v => v.Errors)
            .Select(e => e.ErrorMessage));

        return new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(new
        {
            message = string.IsNullOrWhiteSpace(message) ? "Nevalidan zahtjev." : message
        });
    };
});

builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Unesi JWT token (bez riječi 'Bearer', to Swagger doda sam)"
    });

    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        { new OpenApiSecuritySchemeReference("Bearer", document), new List<string>() }
    });
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection nije postavljen u .env fajlu.");

builder.Services.AddDbContext<ActiveTogetherDbContext>(options =>
    options.UseSqlServer(connectionString));

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key nije postavljen u .env fajlu.");
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

var stripeSecretKey = builder.Configuration["Stripe:SecretKey"]
    ?? throw new InvalidOperationException("Stripe:SecretKey nije postavljen u .env fajlu.");
Stripe.StripeConfiguration.ApiKey = stripeSecretKey;

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();
builder.Services.AddSignalR();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IActivityTypeService, ActivityTypeService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<IActivityService, ActivityService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<IRecommendationService, RecommendationService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddSingleton<IRabbitMqPublisher, RabbitMqPublisher>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IOrganizerRequestService, OrganizerRequestService>();
builder.Services.AddScoped<IProfileService, ProfileService>();
builder.Services.AddScoped<IRatingService, RatingService>();
builder.Services.AddScoped<IFileUploadService, FileUploadService>();
builder.Services.AddScoped<IFavoriteService, FavoriteService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

app.UseMiddleware<ActiveTogether.WebAPI.Middleware.ExceptionHandlingMiddleware>();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ActiveTogetherDbContext>();
    await db.Database.MigrateAsync();
    await DatabaseSeeder.SeedAsync(db);
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");

app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();



app.MapControllers();

app.MapHub<ActiveTogether.Services.Messaging.NotificationsHub>("/hubs/notifications");

app.Run();