using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class ProfileUpdateRequest
    {
        [Required, MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required, MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [MaxLength(30)]
        [RegularExpression(@"^[0-9+()\-\s]{6,30}$", ErrorMessage = "Broj telefona nije u ispravnom formatu.")]
        public string? PhoneNumber { get; set; }

        public int? CityId { get; set; }

        public string? ProfileImageUrl { get; set; }
    }
}