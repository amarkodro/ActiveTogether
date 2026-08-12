using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class ActivityTypeService : IActivityTypeService
    {
        private readonly ActiveTogetherDbContext _context;

        public ActivityTypeService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<List<ActivityTypeResponse>> GetAllAsync()
        {
            return await _context.ActivityTypes
                .OrderBy(a => a.Name)
                .Select(a => new ActivityTypeResponse { Id = a.Id, Name = a.Name })
                .ToListAsync();
        }

        public async Task<ActivityTypeResponse> GetByIdAsync(int id)
        {
            var activityType = await _context.ActivityTypes.FindAsync(id)
                ?? throw new NotFoundException($"Tip aktivnosti sa Id {id} ne postoji.");

            return new ActivityTypeResponse { Id = activityType.Id, Name = activityType.Name };
        }

        public async Task<ActivityTypeResponse> CreateAsync(ActivityTypeUpsertRequest request)
        {
            var activityType = new ActivityType { Name = request.Name };

            _context.ActivityTypes.Add(activityType);
            await _context.SaveChangesAsync();

            return new ActivityTypeResponse { Id = activityType.Id, Name = activityType.Name };
        }

        public async Task<ActivityTypeResponse> UpdateAsync(int id, ActivityTypeUpsertRequest request)
        {
            var activityType = await _context.ActivityTypes.FindAsync(id)
                ?? throw new NotFoundException($"Tip aktivnosti sa Id {id} ne postoji.");

            activityType.Name = request.Name;
            await _context.SaveChangesAsync();

            return new ActivityTypeResponse { Id = activityType.Id, Name = activityType.Name };
        }

        public async Task DeleteAsync(int id)
        {
            var activityType = await _context.ActivityTypes.FindAsync(id)
                ?? throw new NotFoundException($"Tip aktivnosti sa Id {id} ne postoji.");

            _context.ActivityTypes.Remove(activityType);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                throw new BusinessException("Tip aktivnosti se ne može obrisati jer je u upotrebi (koristi ga jedna ili više aktivnosti).");
            }
        }
    }
}