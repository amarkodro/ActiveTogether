using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using ActiveTogether.Model.Enums;

namespace ActiveTogether.Services.Database.Entities
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(User))]
        public int UserId { get; set; }
        public User? User { get; set; }

        [ForeignKey(nameof(Activity))]
        public int ActivityId { get; set; }
        public Activity? Activity { get; set; }

        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ConfirmedAt { get; set; }
        public DateTime? CompletedAt { get; set; }

        public string? CancellationReason { get; set; }
        public DateTime? CancelledAt { get; set; }
        public int? CancelledByUserId { get; set; }

        public Payment? Payment { get; set; }
        public Rating? Rating { get; set; }
    }
}