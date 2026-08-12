using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using ActiveTogether.Model.Enums;

namespace ActiveTogether.Services.Database.Entities
{
    public class Activity
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(1000)]
        public string Description { get; set; } = string.Empty;

        [ForeignKey(nameof(Category))]
        public int CategoryId { get; set; }
        public Category? Category { get; set; }

        [ForeignKey(nameof(ActivityType))]
        public int ActivityTypeId { get; set; }
        public ActivityType? ActivityType { get; set; }

        [ForeignKey(nameof(Location))]
        public int LocationId { get; set; }
        public Location? Location { get; set; }

        [ForeignKey(nameof(Organizer))]
        public int OrganizerId { get; set; }
        public User? Organizer { get; set; }

        public DateTime DateTime { get; set; }

        public int Capacity { get; set; }

        public bool IsFree { get; set; } = true;

        public decimal? Price { get; set; }

        public string? ImageUrl { get; set; }

        public ActivityStatus Status { get; set; } = ActivityStatus.Draft;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}