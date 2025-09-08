namespace Eshop.Domain.Entities
{
    public class ProductCategory
    {
        public long ProductId { get; set; }
        public Product Product { get; set; } = null!;

        public long CategoryId { get; set; }
        public Category Category { get; set; } = null!;

        // public int SortOrder { get; set; }
        // public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

}