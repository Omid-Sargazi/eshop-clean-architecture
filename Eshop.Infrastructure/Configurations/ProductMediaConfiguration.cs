using Eshop.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Eshop.Infrastructure.Configurations
{
    public class ProductMediaConfiguration : IEntityTypeConfiguration<ProductMedia>
    {
        public void Configure(EntityTypeBuilder<ProductMedia> builder)
        {
            builder.ToTable("ProductMedia");

            builder.HasKey(pm => pm.Id);

            builder.Property(pm => pm.Url)
                .IsRequired()
                .HasMaxLength(512);

            builder.Property(pm => pm.AltText)
                .HasMaxLength(256);

            builder.HasOne(pm => pm.Product)
                .WithMany(p => p.Media)
                .HasForeignKey(pm => pm.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}