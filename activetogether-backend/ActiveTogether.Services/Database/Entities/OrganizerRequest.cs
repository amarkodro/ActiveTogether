using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using ActiveTogether.Model.Enums;

namespace ActiveTogether.Services.Database.Entities
{
    public class OrganizerRequest
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(User))]
        public int UserId { get; set; }
        public User? User { get; set; }

        public OrganizerRequestStatus Status { get; set; } = OrganizerRequestStatus.Pending;

        [MaxLength(500)]
        public string? RejectionReason { get; set; }

        [ForeignKey(nameof(DecidedByUser))]
        public int? DecidedByUserId { get; set; }
        public User? DecidedByUser { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DecidedAt { get; set; }
    }
}