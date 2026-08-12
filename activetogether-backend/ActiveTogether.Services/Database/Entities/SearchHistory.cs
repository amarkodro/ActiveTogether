using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ActiveTogether.Services.Database.Entities
{
    public class SearchHistory
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(User))]
        public int UserId { get; set; }
        public User? User { get; set; }

        [MaxLength(150)]
        public string? SearchTerm { get; set; }

        [ForeignKey(nameof(Category))]
        public int? CategoryId { get; set; }
        public Category? Category { get; set; }

        [ForeignKey(nameof(City))]
        public int? CityId { get; set; }
        public City? City { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}