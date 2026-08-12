namespace ActiveTogether.Services.Interfaces
{
    public interface IReportService
    {
        Task<byte[]> GenerateActivityPopularityReportAsync(DateTime? dateFrom, DateTime? dateTo);
        Task<byte[]> GenerateUserActivityReportAsync(DateTime? dateFrom, DateTime? dateTo);
    }
}