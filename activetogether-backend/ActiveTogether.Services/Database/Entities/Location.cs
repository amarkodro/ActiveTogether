using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ActiveTogether.Services.Database.Entities
{
    public class Location
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(200)]
        public string Address { get; set; } = string.Empty;

        [ForeignKey(nameof(City))]
        public int CityId { get; set; }
        public City? City { get; set; }

        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}