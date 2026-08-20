using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class RatingCreateRequest
    {
        [Required]
        public int ReservationId { get; set; }

        [Range(1, 5)]
        public int Score { get; set; }

        [MaxLength(500)]
        public string? Comment { get; set; }
    }
}