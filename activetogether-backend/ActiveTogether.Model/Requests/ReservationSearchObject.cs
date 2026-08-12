namespace ActiveTogether.Model.Requests
{
    public class ReservationSearchObject
    {
        public int? ActivityId { get; set; }
        public string? Status { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}