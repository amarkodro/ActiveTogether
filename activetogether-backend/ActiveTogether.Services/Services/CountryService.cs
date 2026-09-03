using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class CountryService : ICountryService
    {
        private const int MaxPageSize = 50;

        private readonly ActiveTogetherDbContext _context;

        public CountryService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<List<CountryResponse>> GetAllAsync()
        {
            return await _context.Countries
                .OrderBy(c => c.Name)
                .Select(c => new CountryResponse { Id = c.Id, Name = c.Name })
                .ToListAsync();
        }

        public async Task<PagedResult<CountryResponse>> GetPagedAsync(ReferenceSearchObject search)
        {
            var query = _context.Countries.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            var totalCount = await query.CountAsync();
            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var items = await query
                .OrderBy(c => c.Name)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(c => new CountryResponse { Id = c.Id, Name = c.Name })
                .ToListAsync();

            return new PagedResult<CountryResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<CountryResponse> GetByIdAsync(int id)
        {
            var country = await _context.Countries.FindAsync(id)
                ?? throw new NotFoundException($"Država sa Id {id} ne postoji.");

            return new CountryResponse { Id = country.Id, Name = country.Name };
        }

        public async Task<CountryResponse> CreateAsync(CountryUpsertRequest request)
        {
            var country = new Country { Name = request.Name };

            _context.Countries.Add(country);
            await _context.SaveChangesAsync();

            return new CountryResponse { Id = country.Id, Name = country.Name };
        }

        public async Task<CountryResponse> UpdateAsync(int id, CountryUpsertRequest request)
        {
            var country = await _context.Countries.FindAsync(id)
                ?? throw new NotFoundException($"Država sa Id {id} ne postoji.");

            country.Name = request.Name;
            await _context.SaveChangesAsync();

            return new CountryResponse { Id = country.Id, Name = country.Name };
        }

        public async Task DeleteAsync(int id)
        {
            var country = await _context.Countries.FindAsync(id)
                ?? throw new NotFoundException($"Država sa Id {id} ne postoji.");

            _context.Countries.Remove(country);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                throw new BusinessException("Država se ne može obrisati jer je u upotrebi (koristi je jedan ili više gradova).");
            }
        }
    }
}