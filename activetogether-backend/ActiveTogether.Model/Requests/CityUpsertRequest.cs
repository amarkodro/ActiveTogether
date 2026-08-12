namespace ActiveTogether.Model.Requests
{
    public class CityUpsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public int CountryId { get; set; }
    }
}