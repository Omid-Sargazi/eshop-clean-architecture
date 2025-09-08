using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class Order : AuditableEntity
    {
        public long UserId { get; set; }
        public User User { get; set; } = null!;

        public string OrderNo { get; set; } = string.Empty;
        public int Status { get; set; } = 0; // 0=Pending,1=Paid,2=Shipped...

        public decimal Subtotal { get; set; }
        public decimal DiscountTotal { get; set; }
        public decimal ShippingFee { get; set; }
        public decimal TaxTotal { get; set; }
        public decimal GrandTotal { get; set; }

        public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    }
}