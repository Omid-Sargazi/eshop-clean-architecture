using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class Inventory : BaseEntity
    {
        public long VariantId { get; set; }
        public ProductVariant Variant { get; set; } = null!;

        public int Quantity { get; set; }
        public int Reserved { get; set; }
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}