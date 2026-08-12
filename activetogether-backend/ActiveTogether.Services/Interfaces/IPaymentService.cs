using ActiveTogether.Model.Responses;

namespace ActiveTogether.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<PaymentInfoResponse> CreatePaymentIntentAsync(int reservationId, decimal amount);
        Task<PaymentInfoResponse> ConfirmPaymentAsync(int reservationId, int userId);
        Task RefundPaymentAsync(int reservationId);
    }
}