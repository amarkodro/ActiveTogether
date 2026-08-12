namespace ActiveTogether.Model.Requests
{
    public class ActivitySearchObject
    {
        public string? Name { get; set; }
        public int? CategoryId { get; set; }
        public int? ActivityTypeId { get; set; }
        public int? CityId { get; set; }
        public bool? IsFree { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public int? OrganizerId { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}