using ActiveTogether.Model.Enums;

namespace ActiveTogether.Model.Requests
{
    public class OrganizerRequestSearchObject
    {
        public OrganizerRequestStatus? Status { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}