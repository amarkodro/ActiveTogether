using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Država je obavezna.")]
        public int CountryId { get; set; }
    }
}
