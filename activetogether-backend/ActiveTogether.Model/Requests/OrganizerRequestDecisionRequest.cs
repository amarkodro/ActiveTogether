using System.ComponentModel.DataAnnotations;

namespace ActiveTogether.Model.Requests
{
    public class OrganizerRequestDecisionRequest
    {
        [MaxLength(500)]
        public string? Reason { get; set; }
    }
}