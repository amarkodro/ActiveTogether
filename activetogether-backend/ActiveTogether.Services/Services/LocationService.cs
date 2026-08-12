using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class LocationService : ILocationService
    {
        private readonly ActiveTogetherDbContext _context;

        public LocationService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<List<LocationResponse>> GetAllAsync()
        {
            var locations = await _context.Locations
                .Include(l => l.City)
                .OrderBy(l => l.Name)
                .ToListAsync();

            return locations.Select(MapToResponse).ToList();
        }

        public async Task<LocationResponse> GetByIdAsync(int id)
        {
            var location = await _context.Locations
                .Include(l => l.City)
                .FirstOrDefaultAsync(l => l.Id == id)
                ?? throw new NotFoundException($"Lokacija sa Id {id} ne postoji.");

            return MapToResponse(location);
        }

        public async Task<LocationResponse> CreateAsync(LocationUpsertRequest request)
        {
            await EnsureCityExistsAsync(request.CityId);

            var location = new Location
            {
                Name = request.Name,
                Address = request.Address,
                CityId = request.CityId,
                Latitude = request.Latitude,
                Longitude = request.Longitude
            };

            _context.Locations.Add(location);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(location.Id);
        }

        public async Task<LocationResponse> UpdateAsync(int id, LocationUpsertRequest request)
        {
            var location = await _context.Locations.FindAsync(id)
                ?? throw new NotFoundException($"Lokacija sa Id {id} ne postoji.");

            await EnsureCityExistsAsync(request.CityId);

            location.Name = request.Name;
            location.Address = request.Address;
            location.CityId = request.CityId;
            location.Latitude = request.Latitude;
            location.Longitude = request.Longitude;
            await _context.SaveChangesAsync();

            return await GetByIdAsync(location.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var location = await _context.Locations.FindAsync(id)
                ?? throw new NotFoundException($"Lokacija sa Id {id} ne postoji.");

            _context.Locations.Remove(location);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                throw new BusinessException("Lokacija se ne može obrisati jer je u upotrebi (koristi je jedna ili više aktivnosti).");
            }
        }

        private async Task EnsureCityExistsAsync(int cityId)
        {
            var exists = await _context.Cities.AnyAsync(c => c.Id == cityId);
            if (!exists)
                throw new NotFoundException($"Grad sa Id {cityId} ne postoji.");
        }

        private static LocationResponse MapToResponse(Location location)
        {
            return new LocationResponse
            {
                Id = location.Id,
                Name = location.Name,
                Address = location.Address,
                CityId = location.CityId,
                CityName = location.City?.Name ?? string.Empty,
                Latitude = location.Latitude,
                Longitude = location.Longitude
            };
        }
    }
}