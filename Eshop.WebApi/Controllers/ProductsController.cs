using Eshop.Infrastructure.Data;
using Eshop.WebApi.Features.Catalog;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Eshop.WebApi.Controllers
{
    [ApiController]
    [Route("api/catalog/products")]
    public class ProductsController : ControllerBase
    {
        private readonly EshopDbContext _db;
        public ProductsController(EshopDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ProductListItemDto>>> GetList(
        [FromQuery] string? search = null,
        [FromQuery(Name = "category")] string? categorySlug = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 12)
        {
            if (page <= 0) page = 1;
            if (pageSize <= 0 || pageSize > 100) pageSize = 12;

            var q = _db.Products
                .AsNoTracking()
                .Where(p => !p.IsDeleted && p.Status == 1);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim();
                q = q.Where(p => p.Name.Contains(s) || p.Sku.Contains(s) || p.Slug.Contains(s));
            }

            if (!string.IsNullOrWhiteSpace(categorySlug))
            {
                var slug = categorySlug.Trim();
                q = q.Where(p => p.ProductCategories.Any(pc => pc.Category.Slug == slug));
            }

            // join کوچک برای Thumbnail
            var items = await q
                .OrderByDescending(p => p.Id)
                .Select(p => new ProductListItemDto(
                    p.Id,
                    p.Sku,
                    p.Name,
                    p.Slug,
                    p.Description,
                    p.BasePrice,
                    p.Status,
                    p.Media
                            .OrderBy(m => m.SortOrder)
                            .Select(m => m.Url)
                            .FirstOrDefault()
                ))
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(items);
        }
    }
}