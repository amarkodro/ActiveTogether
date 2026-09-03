using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class ActivityUpsertRequest
    {
        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(1000)]
        public string Description { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Kategorija je obavezna.")]
        public int CategoryId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Tip aktivnosti je obavezan.")]
        public int ActivityTypeId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Lokacija je obavezna.")]
        public int LocationId { get; set; }

        public DateTime DateTime { get; set; }

        [Range(1, 1000, ErrorMessage = "Kapacitet mora biti između 1 i 1000.")]
        public int Capacity { get; set; }

        public bool IsFree { get; set; } = true;

        [Range(0.01, 100000, ErrorMessage = "Cijena mora biti veća od nule.")]
        public decimal? Price { get; set; }

        [MaxLength(2000)]
        public string? ImageUrl { get; set; }
    }
}
