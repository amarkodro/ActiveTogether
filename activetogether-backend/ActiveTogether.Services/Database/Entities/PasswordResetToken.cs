using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ActiveTogether.Services.Database.Entities
{
    public class PasswordResetToken
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(User))]
        public int UserId { get; set; }
        public User? User { get; set; }

        [Required, MaxLength(10)]
        public string Code { get; set; } = string.Empty;

        public DateTime ExpiresAt { get; set; }
        public bool IsUsed { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}