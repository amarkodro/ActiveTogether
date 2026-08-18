using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IOrganizerRequestService
    {
        Task<OrganizerRequestResponse> CreateAsync(int userId);
        Task<PagedResult<OrganizerRequestResponse>> GetAllAsync(OrganizerRequestSearchObject search);
        Task<OrganizerRequestResponse> ApproveAsync(int id, int adminId);
        Task<OrganizerRequestResponse> RejectAsync(int id, int adminId, string? reason);
    }
}