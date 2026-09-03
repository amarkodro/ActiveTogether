namespace ActiveTogether.Model.Responses
{
    public class RatingResponse
    {
        public int Id { get; set; }
        public int ReservationId { get; set; }
        public int ActivityId { get; set; }
        public int UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string? UserProfileImageUrl { get; set; }
        public int Score { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}