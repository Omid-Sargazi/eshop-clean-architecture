using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class Product : AuditableEntity
    {
        public string Sku { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Slug { get; set; } = string.Empty;
        public string? Description { get; set; }
        public decimal BasePrice { get; set; }
        public byte Status { get; set; } = 1; // 0=Draft,1=Active,2=Archived

        public ICollection<ProductVariant> Variants { get; set; } = new List<ProductVariant>();
        public ICollection<ProductCategory> ProductCategories { get; set; } = new List<ProductCategory>();
          public ICollection<ProductMedia> Media { get; set; } = new List<ProductMedia>();
    }
}