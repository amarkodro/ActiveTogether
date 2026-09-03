using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class LocationUpsertRequest
    {
        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(250)]
        public string Address { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Grad je obavezan.")]
        public int CityId { get; set; }

        [Range(-90, 90, ErrorMessage = "Geografska širina mora biti između -90 i 90.")]
        public double Latitude { get; set; }

        [Range(-180, 180, ErrorMessage = "Geografska dužina mora biti između -180 i 180.")]
        public double Longitude { get; set; }
    }
}
