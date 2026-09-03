namespace ActiveTogether.Model.Requests
{
    public class ReferenceSearchObject
    {
        public string? Name { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}
