namespace ActiveTogether.Model.Requests
{
    public class LocationUpsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public int CityId { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}