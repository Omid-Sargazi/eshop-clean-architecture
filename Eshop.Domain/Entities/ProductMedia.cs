using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class ProductMedia : AuditableEntity
    {
        public long ProductId { get; set; }
        public Product Product { get; set; } = null!;

        public string Url { get; set; } = string.Empty;
        public string? AltText { get; set; }
        public int SortOrder { get; set; }
    }
}