using ActiveTogether.Model.Enums;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System.IO;

namespace ActiveTogether.Services.Services
{
    public class ReportService : IReportService
    {
        private readonly ActiveTogetherDbContext _context;
        private readonly byte[] _logoBytes;

        public ReportService(ActiveTogetherDbContext context)
        {
            _context = context;
            var logoPath = Path.Combine(AppContext.BaseDirectory, "Resources", "logo.png");
            _logoBytes = File.Exists(logoPath) ? File.ReadAllBytes(logoPath) : Array.Empty<byte>();
        }

        public async Task<byte[]> GenerateActivityPopularityReportAsync(DateTime? dateFrom, DateTime? dateTo)
        {
            var query = _context.Activities
                .Include(a => a.Category)
                .Include(a => a.Organizer)
                .AsQueryable();

            if (dateFrom.HasValue)
                query = query.Where(a => a.DateTime >= dateFrom.Value);

            if (dateTo.HasValue)
                query = query.Where(a => a.DateTime <= dateTo.Value);

            var activities = await query.ToListAsync();
            var activityIds = activities.Select(a => a.Id).ToList();

            var reservedCounts = await _context.Reservations
                .Where(r => activityIds.Contains(r.ActivityId) && r.Status != ReservationStatus.Cancelled)
                .GroupBy(r => r.ActivityId)
                .Select(g => new { ActivityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.ActivityId, x => x.Count);

            var avgRatings = await _context.Ratings
                .Where(r => activityIds.Contains(r.ActivityId))
                .GroupBy(r => r.ActivityId)
                .Select(g => new { ActivityId = g.Key, Avg = g.Average(x => x.Score) })
                .ToDictionaryAsync(x => x.ActivityId, x => x.Avg);

            var rows = activities
                .Select(a => new
                {
                    a.Name,
                    Category = a.Category?.Name ?? "-",
                    Organizer = a.Organizer is null ? "-" : $"{a.Organizer.FirstName} {a.Organizer.LastName}",
                    a.DateTime,
                    Reserved = reservedCounts.GetValueOrDefault(a.Id),
                    a.Capacity,
                    AvgRating = avgRatings.GetValueOrDefault(a.Id)
                })
                .OrderByDescending(x => x.Reserved)
                .ToList();

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(30);
                    page.DefaultTextStyle(x => x.FontSize(9));

                    page.Header().Row(row =>
                    {
                        if (_logoBytes.Length > 0)
                            row.ConstantItem(70).Height(70).Image(_logoBytes).FitArea();

                        row.RelativeItem().PaddingLeft(_logoBytes.Length > 0 ? 10 : 0).Column(col =>
                        {
                            col.Item().Text("ActiveTogether - Izvještaj: Popularnost aktivnosti").FontSize(16).Bold();
                            col.Item().Text($"Period: {(dateFrom?.ToString("dd.MM.yyyy") ?? "-")} — {(dateTo?.ToString("dd.MM.yyyy") ?? "-")}").FontSize(10);
                            col.Item().Text($"Generisano: {DateTime.Now:dd.MM.yyyy HH:mm}").FontSize(8);
                            col.Item().PaddingBottom(10);
                        });
                    });

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(3);
                            columns.RelativeColumn(2);
                            columns.RelativeColumn(2);
                            columns.RelativeColumn(2);
                            columns.RelativeColumn(2);
                            columns.RelativeColumn(1);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Text("Naziv").Bold();
                            header.Cell().Text("Kategorija").Bold();
                            header.Cell().Text("Organizator").Bold();
                            header.Cell().Text("Datum").Bold();
                            header.Cell().Text("Rezervacije").Bold();
                            header.Cell().Text("Ocjena").Bold();
                        });

                        foreach (var row in rows)
                        {
                            table.Cell().Text(row.Name);
                            table.Cell().Text(row.Category);
                            table.Cell().Text(row.Organizer);
                            table.Cell().Text(row.DateTime.ToString("dd.MM.yyyy"));
                            table.Cell().Text($"{row.Reserved}/{row.Capacity}");
                            table.Cell().Text(row.AvgRating > 0 ? row.AvgRating.ToString("0.0") : "-");
                        }
                    });

                    page.Footer().AlignCenter().Text(x =>
                    {
                        x.CurrentPageNumber();
                        x.Span(" / ");
                        x.TotalPages();
                    });
                });
            }).GeneratePdf();
        }

        public async Task<byte[]> GenerateUserActivityReportAsync(DateTime? dateFrom, DateTime? dateTo)
        {
            var users = await _context.Users.ToListAsync();
            var userIds = users.Select(u => u.Id).ToList();

            var reservationQuery = _context.Reservations.Where(r => userIds.Contains(r.UserId));

            if (dateFrom.HasValue)
                reservationQuery = reservationQuery.Where(r => r.CreatedAt >= dateFrom.Value);

            if (dateTo.HasValue)
                reservationQuery = reservationQuery.Where(r => r.CreatedAt <= dateTo.Value);

            var reservationStats = await reservationQuery
                .GroupBy(r => r.UserId)
                .Select(g => new { UserId = g.Key, Total = g.Count(), Completed = g.Count(x => x.Status == ReservationStatus.Completed) })
                .ToListAsync();

            var statsLookup = reservationStats.ToDictionary(x => x.UserId, x => (x.Total, x.Completed));

            var rows = users
                .Select(u =>
                {
                    var (total, completed) = statsLookup.TryGetValue(u.Id, out var s) ? s : (0, 0);
                    return new
                    {
                        Name = $"{u.FirstName} {u.LastName}",
                        u.Email,
                        u.Role,
                        Total = total,
                        Completed = completed
                    };
                })
                .OrderByDescending(x => x.Total)
                .ToList();

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(30);
                    page.DefaultTextStyle(x => x.FontSize(9));

                    page.Header().Column(col =>
                    {
                        col.Item().Text("ActiveTogether — Izvještaj: Aktivnost korisnika").FontSize(16).Bold();
                        col.Item().Text($"Period: {(dateFrom?.ToString("dd.MM.yyyy") ?? "-")} — {(dateTo?.ToString("dd.MM.yyyy") ?? "-")}").FontSize(10);
                        col.Item().Text($"Generisano: {DateTime.Now:dd.MM.yyyy HH:mm}").FontSize(8);
                        col.Item().PaddingBottom(10);
                    });

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(3);
                            columns.RelativeColumn(3);
                            columns.RelativeColumn(2);
                            columns.RelativeColumn(2);
                            columns.RelativeColumn(2);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Text("Ime i prezime").Bold();
                            header.Cell().Text("Email").Bold();
                            header.Cell().Text("Uloga").Bold();
                            header.Cell().Text("Rezervacije").Bold();
                            header.Cell().Text("Završeno").Bold();
                        });

                        foreach (var row in rows)
                        {
                            table.Cell().Text(row.Name);
                            table.Cell().Text(row.Email);
                            table.Cell().Text(row.Role);
                            table.Cell().Text(row.Total.ToString());
                            table.Cell().Text(row.Completed.ToString());
                        }
                    });

                    page.Footer().AlignCenter().Text(x =>
                    {
                        x.CurrentPageNumber();
                        x.Span(" / ");
                        x.TotalPages();
                    });
                });
            }).GeneratePdf();
        }
    }
}