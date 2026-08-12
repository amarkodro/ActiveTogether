namespace ActiveTogether.Model.Responses
{
    public class RecommendedActivityResponse
    {
        public ActivityResponse Activity { get; set; } = null!;
        public string Reason { get; set; } = string.Empty;
    }
}