using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class ChangePasswordRequest
    {
        [Required]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required, MinLength(8)]
        [RegularExpression(@"^(?=.*[A-Za-z])(?=.*\d).+$", ErrorMessage = "Lozinka mora sadržavati bar jedno slovo i jedan broj.")]
        public string NewPassword { get; set; } = string.Empty;
    }
}