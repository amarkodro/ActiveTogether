using ActiveTogether.Model.Exceptions;
using ActiveTogether.Model.Requests;
using ActiveTogether.Model.Responses;
using ActiveTogether.Services.Database;
using ActiveTogether.Services.Database.Entities;
using ActiveTogether.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace ActiveTogether.Services.Services
{
    public class CategoryService : ICategoryService
    {
        private readonly ActiveTogetherDbContext _context;

        public CategoryService(ActiveTogetherDbContext context)
        {
            _context = context;
        }

        public async Task<List<CategoryResponse>> GetAllAsync()
        {
            return await _context.Categories
                .OrderBy(c => c.Name)
                .Select(c => new CategoryResponse { Id = c.Id, Name = c.Name })
                .ToListAsync();
        }

        public async Task<CategoryResponse> GetByIdAsync(int id)
        {
            var category = await _context.Categories.FindAsync(id)
                ?? throw new NotFoundException($"Kategorija sa Id {id} ne postoji.");

            return new CategoryResponse { Id = category.Id, Name = category.Name };
        }

        public async Task<CategoryResponse> CreateAsync(CategoryUpsertRequest request)
        {
            var category = new Category { Name = request.Name };

            _context.Categories.Add(category);
            await _context.SaveChangesAsync();

            return new CategoryResponse { Id = category.Id, Name = category.Name };
        }

        public async Task<CategoryResponse> UpdateAsync(int id, CategoryUpsertRequest request)
        {
            var category = await _context.Categories.FindAsync(id)
                ?? throw new NotFoundException($"Kategorija sa Id {id} ne postoji.");

            category.Name = request.Name;
            await _context.SaveChangesAsync();

            return new CategoryResponse { Id = category.Id, Name = category.Name };
        }

        public async Task DeleteAsync(int id)
        {
            var category = await _context.Categories.FindAsync(id)
                ?? throw new NotFoundException($"Kategorija sa Id {id} ne postoji.");

            _context.Categories.Remove(category);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                throw new BusinessException("Kategorija se ne može obrisati jer je u upotrebi (koristi je jedna ili više aktivnosti).");
            }
        }
    }
}