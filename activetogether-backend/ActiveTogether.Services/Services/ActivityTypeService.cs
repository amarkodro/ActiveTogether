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
        private const int MaxPageSize = 50;

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

        public async Task<PagedResult<ActivityTypeResponse>> GetPagedAsync(ReferenceSearchObject search)
        {
            var query = _context.ActivityTypes.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(a => a.Name.Contains(search.Name));

            var totalCount = await query.CountAsync();
            var pageSize = Math.Clamp(search.PageSize, 1, MaxPageSize);
            var page = Math.Max(search.Page, 1);

            var items = await query
                .OrderBy(a => a.Name)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(a => new ActivityTypeResponse { Id = a.Id, Name = a.Name })
                .ToListAsync();

            return new PagedResult<ActivityTypeResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
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