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