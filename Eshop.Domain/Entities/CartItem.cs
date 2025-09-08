using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class CartItem : BaseEntity
    {
        public long CartId { get; set; }
        public Cart Cart { get; set; } = null!;

        public long VariantId { get; set; }
        public ProductVariant Variant { get; set; } = null!;

        public int Qty { get; set; }
        public decimal UnitPrice { get; set; }
    }
}