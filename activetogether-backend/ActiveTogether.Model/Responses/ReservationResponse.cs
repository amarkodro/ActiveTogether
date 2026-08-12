namespace ActiveTogether.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int ActivityId { get; set; }
        public string ActivityName { get; set; } = string.Empty;
        public DateTime ActivityDateTime { get; set; }
        public int UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? ConfirmedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public string? CancellationReason { get; set; }
        public DateTime? CancelledAt { get; set; }
        public PaymentInfoResponse? Payment { get; set; }

    }
}