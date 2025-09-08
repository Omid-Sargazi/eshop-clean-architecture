using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class Cart : AuditableEntity
    {
        public long UserId { get; set; }
        public User User { get; set; } = null!;

        public ICollection<CartItem> Items { get; set; } = new List<CartItem>();
    }
}