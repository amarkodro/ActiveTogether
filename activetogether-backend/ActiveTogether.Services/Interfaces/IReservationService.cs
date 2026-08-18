using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IReservationService
    {
        Task<PagedResult<ReservationResponse>> GetMyReservationsAsync(int userId, ReservationSearchObject search);
        Task<PagedResult<ReservationResponse>> GetForActivityAsync(int activityId, ReservationSearchObject search, int currentUserId, bool isAdmin);
        Task<ReservationResponse> CreateAsync(ReservationCreateRequest request, int userId);
        Task<ReservationResponse> ConfirmAsync(int id, int currentUserId, bool isAdmin);
        Task<ReservationResponse> CompleteAsync(int id, int currentUserId, bool isAdmin);
        Task<ReservationResponse> CancelAsync(int id, ReservationCancelRequest request, int currentUserId, bool isAdmin);
        Task<PagedResult<ReservationResponse>> GetAllAsync(ReservationSearchObject search);
        Task<PagedResult<ReservationResponse>> GetForOrganizerAsync(int organizerId, ReservationSearchObject search);
    }
}