namespace ActiveTogether.Model.Responses
{
    public class ActivityResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public int ActivityTypeId { get; set; }
        public string ActivityTypeName { get; set; } = string.Empty;
        public int LocationId { get; set; }
        public string LocationName { get; set; } = string.Empty;
        public string LocationAddress { get; set; } = string.Empty;
        public int OrganizerId { get; set; }
        public string OrganizerName { get; set; } = string.Empty;
        public DateTime DateTime { get; set; }
        public int Capacity { get; set; }
        public int ReservedCount { get; set; }
        public bool IsFree { get; set; }
        public decimal? Price { get; set; }
        public string? ImageUrl { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}