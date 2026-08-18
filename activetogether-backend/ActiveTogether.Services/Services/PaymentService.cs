using ActiveTogether.Model.Enums;
using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace ActiveTogether.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private const string Currency = "eur";

        private readonly ActiveTogetherDbContext _context;
        private readonly INotificationService _notificationService;

        public PaymentService(ActiveTogetherDbContext context, INotificationService notificationService)
        {
            _context = context;
            _notificationService = notificationService;
        }

        public async Task<PaymentInfoResponse> CreatePaymentIntentAsync(int reservationId, decimal amount)
        {
            var paymentIntentService = new PaymentIntentService();
            var intent = await paymentIntentService.CreateAsync(new PaymentIntentCreateOptions
            {
                Amount = (long)(amount * 100),
                Currency = Currency,
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true,
                    AllowRedirects = "never"
                },
                Metadata = new Dictionary<string, string>
                {
                    { "reservationId", reservationId.ToString() }
                }
            });

            var payment = new Payment
            {
                ReservationId = reservationId,
                Amount = amount,
                Status = PaymentStatus.Pending,
                StripePaymentIntentId = intent.Id,
                CreatedAt = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            return MapToResponse(payment, intent.ClientSecret);
        }

        public async Task<PaymentInfoResponse> ConfirmPaymentAsync(int reservationId, int userId)
        {
            var payment = await _context.Payments
                .Include(p => p.Reservation)
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId)
                ?? throw new NotFoundException("Plaćanje za ovu rezervaciju ne postoji.");

            if (payment.Reservation!.UserId != userId)
                throw new BusinessException("Nemate dozvolu za potvrdu ovog plaćanja.");

            if (payment.Status == PaymentStatus.Completed)
                return MapToResponse(payment, null);

            var paymentIntentService = new PaymentIntentService();
            var intent = await paymentIntentService.GetAsync(payment.StripePaymentIntentId);

            if (intent.Status != "succeeded")
                throw new BusinessException($"Plaćanje još nije uspješno završeno (Stripe status: {intent.Status}).");

            payment.Status = PaymentStatus.Completed;
            payment.PaidAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            await _notificationService.NotifyAsync(
              payment.Reservation!.UserId,
              NotificationType.PaymentCompleted,
              "Plaćanje uspješno",
              $"Vaše plaćanje u iznosu od {payment.Amount:0.00} EUR je uspješno završeno.");

            return MapToResponse(payment, null);
        }

        public async Task RefundPaymentAsync(int reservationId)
        {
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId);

            if (payment is null || payment.Status != PaymentStatus.Completed)
                return;

            var refundService = new RefundService();
            await refundService.CreateAsync(new RefundCreateOptions
            {
                PaymentIntent = payment.StripePaymentIntentId
            });

            payment.Status = PaymentStatus.Refunded;
            payment.RefundedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        private static PaymentInfoResponse MapToResponse(Payment payment, string? clientSecret)
        {
            return new PaymentInfoResponse
            {
                Id = payment.Id,
                Amount = payment.Amount,
                Status = payment.Status.ToString(),
                ClientSecret = clientSecret,
                PaidAt = payment.PaidAt,
                RefundedAt = payment.RefundedAt
            };
        }
    }
}