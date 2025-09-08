using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class ProductVariant : AuditableEntity
    {
        public long ProductId { get; set; }
        public Product Product { get; set; } = null!;

        public string Sku { get; set; } = string.Empty;
        public string? AttributesJson { get; set; }
        public decimal Price { get; set; }
        public string? Barcode { get; set; }
        public bool IsActive { get; set; } = true;

         public Inventory Inventory { get; set; } = null!;
    }
}