using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Services.Database.Entities
{
    public class ActivityType
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;
    }
}