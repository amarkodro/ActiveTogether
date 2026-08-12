namespace ActiveTogether.Model.Requests
{
    public class ActivityUpsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public int ActivityTypeId { get; set; }
        public int LocationId { get; set; }
        public DateTime DateTime { get; set; }
        public int Capacity { get; set; }
        public bool IsFree { get; set; } = true;
        public decimal? Price { get; set; }
        public string? ImageUrl { get; set; }
    }
}