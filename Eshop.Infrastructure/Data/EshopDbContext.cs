using Microsoft.EntityFrameworkCore;

namespace Eshop.Infrastructure.Data
{
    public class EshopDbContext : DbContext
    {
        public EshopDbContext(DbContextOptions<EshopDbContext> options) : base(options) { }
         public DbSet<User> Users { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<ProductVariant> ProductVariants { get; set; }
        public DbSet<Cart> Carts { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
    }
}