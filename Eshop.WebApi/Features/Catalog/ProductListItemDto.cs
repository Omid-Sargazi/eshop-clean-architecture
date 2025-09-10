namespace Eshop.WebApi.Features.Catalog
{
    public record ProductListItemDto(
        long Id,
        string Sku,
        string Name,
        string Slug,
        string Description,
        decimal BasePrice,
        byte Status, 
        string? ThumbnailUrl
    );

    public record ProductDetailDto(
         long Id,
        string Sku,
        string Name,
        string Slug,
        string? Description,
        decimal BasePrice,
        int Status,
        IReadOnlyList<string> Images,
        IReadOnlyList<ProductVariantDto> Variants
    );

    public record ProductVariantDto(
        long Id,
        string Sku,
        string? AttributesJson,
        decimal Price,
        bool IsActive,
        int StockQty
    );

}