using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class OrderItem : BaseEntity
    {
        public long OrderId { get; set; }
        public Order Order { get; set; } = null!;

        public long VariantId { get; set; }
        public ProductVariant Variant { get; set; } = null!;

        public string ProductName { get; set; } = string.Empty;
        public string Sku { get; set; } = string.Empty;

        public int Qty { get; set; }
        public decimal UnitPrice { get; set; }
    }
}