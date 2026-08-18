using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class UserUpdateRequest
    {
        [Required, MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required, MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required, MaxLength(150), EmailAddress]
        public string Email { get; set; } = string.Empty;

        [MaxLength(30)]
        public string? PhoneNumber { get; set; }

        public int? CityId { get; set; }
    }
}