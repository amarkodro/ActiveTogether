namespace ActiveTogether.Model.Enums;

/// <summary>
/// Centralizovan, konzistentan set dozvoljenih tranzicija statusa za Activity i Reservation.
/// Servisi treba da provjeravaju dozvoljenost tranzicije kroz ove metode umjesto
/// raštrkanih ad-hoc provjera, kako bi lifecycle pravila bila definisana na jednom mjestu.
/// </summary>
public static class StatusTransitions
{
    private static readonly Dictionary<ActivityStatus, ActivityStatus[]> ActivityAllowed = new()
    {
        [ActivityStatus.Draft] = new[] { ActivityStatus.Active, ActivityStatus.Cancelled },
        [ActivityStatus.Active] = new[] { ActivityStatus.Completed, ActivityStatus.Cancelled },
        [ActivityStatus.Completed] = Array.Empty<ActivityStatus>(),
        [ActivityStatus.Cancelled] = Array.Empty<ActivityStatus>()
    };

    private static readonly Dictionary<ReservationStatus, ReservationStatus[]> ReservationAllowed = new()
    {
        [ReservationStatus.Pending] = new[] { ReservationStatus.Confirmed, ReservationStatus.Cancelled },
        [ReservationStatus.Confirmed] = new[] { ReservationStatus.Completed, ReservationStatus.Cancelled },
        [ReservationStatus.Completed] = Array.Empty<ReservationStatus>(),
        [ReservationStatus.Cancelled] = Array.Empty<ReservationStatus>()
    };

    public static bool CanTransition(ActivityStatus from, ActivityStatus to) =>
        ActivityAllowed.TryGetValue(from, out var allowed) && allowed.Contains(to);

    public static bool CanTransition(ReservationStatus from, ReservationStatus to) =>
        ReservationAllowed.TryGetValue(from, out var allowed) && allowed.Contains(to);
}
