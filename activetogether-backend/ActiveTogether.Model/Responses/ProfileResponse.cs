namespace ActiveTogether.Model.Responses
{
    public class ProfileResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string Role { get; set; } = string.Empty;
        public int? CityId { get; set; }
        public string? CityName { get; set; }
        public string? ProfileImageUrl { get; set; }
        public int TotalReservations { get; set; }
        public int CompletedActivitiesCount { get; set; }
        public double? AverageRatingGiven { get; set; }
    }
}