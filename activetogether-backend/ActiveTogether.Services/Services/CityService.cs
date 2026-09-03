using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class CityService : ICityService
    {
        private const int MaxPageSize = 50;

        private readonly ActiveTogetherDbContext _context;

        public CityService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<List<CityResponse>> GetAllAsync()
        {
            var cities = await _context.Cities
                .Include(c => c.Country)
                .OrderBy(c => c.Name)
                .ToListAsync();

            return cities.Select(MapToResponse).ToList();
        }

        public async Task<PagedResult<CityResponse>> GetPagedAsync(CitySearchObject search)
        {
            var query = _context.Cities.Include(c => c.Country).AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (search.CountryId.HasValue)
                query = query.Where(c => c.CountryId == search.CountryId.Value);

            var totalCount = await query.CountAsync();
            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var cities = await query
                .OrderBy(c => c.Name)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<CityResponse>
            {
                Items = cities.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<CityResponse> GetByIdAsync(int id)
        {
            var city = await _context.Cities
                .Include(c => c.Country)
                .FirstOrDefaultAsync(c => c.Id == id)
                ?? throw new NotFoundException($"Grad sa Id {id} ne postoji.");

            return MapToResponse(city);
        }

        public async Task<CityResponse> CreateAsync(CityUpsertRequest request)
        {
            await EnsureCountryExistsAsync(request.CountryId);

            var city = new City
            {
                Name = request.Name,
                CountryId = request.CountryId
            };

            _context.Cities.Add(city);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(city.Id);
        }

        public async Task<CityResponse> UpdateAsync(int id, CityUpsertRequest request)
        {
            var city = await _context.Cities.FindAsync(id)
                ?? throw new NotFoundException($"Grad sa Id {id} ne postoji.");

            await EnsureCountryExistsAsync(request.CountryId);

            city.Name = request.Name;
            city.CountryId = request.CountryId;
            await _context.SaveChangesAsync();

            return await GetByIdAsync(city.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var city = await _context.Cities.FindAsync(id)
                ?? throw new NotFoundException($"Grad sa Id {id} ne postoji.");

            _context.Cities.Remove(city);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                throw new BusinessException("Grad se ne može obrisati jer je u upotrebi (koriste ga lokacije ili korisnici).");
            }
        }

        private async Task EnsureCountryExistsAsync(int countryId)
        {
            var exists = await _context.Countries.AnyAsync(c => c.Id == countryId);
            if (!exists)
                throw new NotFoundException($"Država sa Id {countryId} ne postoji.");
        }

        private static CityResponse MapToResponse(City city)
        {
            return new CityResponse
            {
                Id = city.Id,
                Name = city.Name,
                CountryId = city.CountryId,
                CountryName = city.Country?.Name ?? string.Empty
            };
        }
    }
}