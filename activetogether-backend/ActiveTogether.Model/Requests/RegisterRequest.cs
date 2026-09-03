using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class RegisterRequest
    {
        [Required, MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required, MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required, MinLength(3), MaxLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required, MaxLength(150), EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, MinLength(6), MaxLength(100)]
        public string Password { get; set; } = string.Empty;

        [MaxLength(30)]
        [RegularExpression(@"^[0-9+()\-\s]{6,30}$", ErrorMessage = "Broj telefona nije u ispravnom formatu.")]
        public string? PhoneNumber { get; set; }

        public int? CityId { get; set; }
    }
}
