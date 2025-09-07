/* === 0) ایجاد دیتابیس (در صورت نیاز) === */
IF DB_ID(N'EshopDb') IS NULL
BEGIN
  CREATE DATABASE EshopDb;
END
GO

USE EshopDb;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* تنظیم Schema */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'dbo')
    EXEC('CREATE SCHEMA dbo');
GO

/* === 1) لغو ترتیب FKها در صورت اجرای مجدد === */
-- اختیاری: برای اسکریپت اولیه نیاز نیست

/* === 2) جداول امنیت/هویت === */
CREATE TABLE dbo.Roles (
    Id           BIGINT IDENTITY PRIMARY KEY,
    Name         NVARCHAR(64) NOT NULL UNIQUE,
    CreatedAt    DATETIME2(3) NOT NULL CONSTRAINT DF_Roles_CreatedAt DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Users (
    Id              BIGINT IDENTITY PRIMARY KEY,
    Email           NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256) NOT NULL,
    FullName        NVARCHAR(128) NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
    IsDeleted       BIT NOT NULL CONSTRAINT DF_Users_IsDeleted DEFAULT 0,
    CreatedAt       DATETIME2(3) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(3) NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_Users_IsActive ON dbo.Users(IsActive);

CREATE TABLE dbo.UserRoles (
    UserId   BIGINT NOT NULL,
    RoleId   BIGINT NOT NULL,
    GrantedAt DATETIME2(3) NOT NULL CONSTRAINT DF_UserRoles_GrantedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(Id) ON DELETE CASCADE
);

CREATE TABLE dbo.RefreshTokens (
    Id            BIGINT IDENTITY PRIMARY KEY,
    UserId        BIGINT NOT NULL,
    Token         NVARCHAR(512) NOT NULL,
    ExpiresAt     DATETIME2(3) NOT NULL,
    RevokedAt     DATETIME2(3) NULL,
    CreatedAt     DATETIME2(3) NOT NULL CONSTRAINT DF_RefreshTokens_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE
);
CREATE INDEX IX_RefreshTokens_User_Active ON dbo.RefreshTokens(UserId, ExpiresAt) WHERE RevokedAt IS NULL;

/* === 3) آدرس‌ها === */
CREATE TABLE dbo.Addresses (
    Id          BIGINT IDENTITY PRIMARY KEY,
    UserId      BIGINT NOT NULL,
    Type        TINYINT NOT NULL,          -- 0=Shipping, 1=Billing
    Line1       NVARCHAR(256) NOT NULL,
    Line2       NVARCHAR(256) NULL,
    City        NVARCHAR(100) NOT NULL,
    State       NVARCHAR(100) NULL,
    PostalCode  NVARCHAR(32) NOT NULL,
    Country     NVARCHAR(64) NOT NULL,
    CreatedAt   DATETIME2(3) NOT NULL CONSTRAINT DF_Addresses_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Addresses_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
    CONSTRAINT CK_Addresses_Type CHECK (Type IN (0,1))
);
CREATE INDEX IX_Addresses_UserId ON dbo.Addresses(UserId);

/* === 4) کاتالوگ: دسته‌ها، محصولات، و رسانه === */
CREATE TABLE dbo.Categories (
    Id          BIGINT IDENTITY PRIMARY KEY,
    Name        NVARCHAR(128) NOT NULL,
    Slug        NVARCHAR(160) NOT NULL UNIQUE,
    ParentId    BIGINT NULL,
    IsDeleted   BIT NOT NULL CONSTRAINT DF_Categories_IsDeleted DEFAULT 0,
    CreatedAt   DATETIME2(3) NOT NULL CONSTRAINT DF_Categories_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentId) REFERENCES dbo.Categories(Id)
);
CREATE INDEX IX_Categories_ParentId ON dbo.Categories(ParentId);

CREATE TABLE dbo.Products (
    Id           BIGINT IDENTITY PRIMARY KEY,
    Sku          NVARCHAR(64) NOT NULL UNIQUE,
    Name         NVARCHAR(256) NOT NULL,
    Slug         NVARCHAR(256) NOT NULL UNIQUE,
    Description  NVARCHAR(MAX) NULL,
    BasePrice    DECIMAL(18,2) NOT NULL CONSTRAINT DF_Products_BasePrice DEFAULT(0),
    Status       TINYINT NOT NULL CONSTRAINT DF_Products_Status DEFAULT 1, -- 0=Draft,1=Active,2=Archived
    IsDeleted    BIT NOT NULL CONSTRAINT DF_Products_IsDeleted DEFAULT 0,
    CreatedAt    DATETIME2(3) NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt    DATETIME2(3) NOT NULL CONSTRAINT DF_Products_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Products_BasePrice CHECK (BasePrice >= 0),
    CONSTRAINT CK_Products_Status CHECK (Status IN (0,1,2))
);
CREATE INDEX IX_Products_Status ON dbo.Products(Status);

CREATE TABLE dbo.ProductCategories (
    ProductId  BIGINT NOT NULL,
    CategoryId BIGINT NOT NULL,
    CONSTRAINT PK_ProductCategories PRIMARY KEY (ProductId, CategoryId),
    CONSTRAINT FK_ProductCategories_Products  FOREIGN KEY (ProductId)  REFERENCES dbo.Products(Id)  ON DELETE CASCADE,
    CONSTRAINT FK_ProductCategories_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories(Id) ON DELETE CASCADE
);

CREATE TABLE dbo.ProductMedia (
    Id         BIGINT IDENTITY PRIMARY KEY,
    ProductId  BIGINT NOT NULL,
    Url        NVARCHAR(512) NOT NULL,
    AltText    NVARCHAR(256) NULL,
    SortOrder  INT NOT NULL CONSTRAINT DF_ProductMedia_SortOrder DEFAULT 0,
    CreatedAt  DATETIME2(3) NOT NULL CONSTRAINT DF_ProductMedia_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ProductMedia_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(Id) ON DELETE CASCADE
);
CREATE INDEX IX_ProductMedia_ProductId ON dbo.ProductMedia(ProductId);

/* === 5) واریانت محصول + انبار === */
CREATE TABLE dbo.ProductVariants (
    Id             BIGINT IDENTITY PRIMARY KEY,
    ProductId      BIGINT NOT NULL,
    Sku            NVARCHAR(64) NOT NULL UNIQUE,
    AttributesJson NVARCHAR(2000) NULL,  -- مثلا رنگ/سایز
    Price          DECIMAL(18,2) NOT NULL,
    Barcode        NVARCHAR(64) NULL,
    IsActive       BIT NOT NULL CONSTRAINT DF_ProductVariants_IsActive DEFAULT 1,
    CreatedAt      DATETIME2(3) NOT NULL CONSTRAINT DF_ProductVariants_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ProductVariants_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(Id) ON DELETE CASCADE,
    CONSTRAINT CK_ProductVariants_Price CHECK (Price >= 0)
);
CREATE INDEX IX_ProductVariants_ProductId ON dbo.ProductVariants(ProductId);

CREATE TABLE dbo.Inventory (
    Id         BIGINT IDENTITY PRIMARY KEY,
    VariantId  BIGINT NOT NULL,
    Quantity   INT NOT NULL CONSTRAINT DF_Inventory_Qty DEFAULT 0,
    Reserved   INT NOT NULL CONSTRAINT DF_Inventory_Reserved DEFAULT 0,
    UpdatedAt  DATETIME2(3) NOT NULL CONSTRAINT DF_Inventory_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Inventory_Variants FOREIGN KEY (VariantId) REFERENCES dbo.ProductVariants(Id) ON DELETE CASCADE,
    CONSTRAINT CK_Inventory_Qty CHECK (Quantity >= 0 AND Reserved >= 0),
    CONSTRAINT CK_Inventory_Balance CHECK (Quantity >= Reserved)
);
CREATE UNIQUE INDEX UX_Inventory_VariantId ON dbo.Inventory(VariantId);

/* === 6) سبد خرید و کوپن === */
CREATE TABLE dbo.Carts (
    Id         BIGINT IDENTITY PRIMARY KEY,
    UserId     BIGINT NOT NULL,
    CreatedAt  DATETIME2(3) NOT NULL CONSTRAINT DF_Carts_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt  DATETIME2(3) NOT NULL CONSTRAINT DF_Carts_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Carts_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE
);
CREATE INDEX IX_Carts_UserId ON dbo.Carts(UserId);

CREATE TABLE dbo.CartItems (
    Id          BIGINT IDENTITY PRIMARY KEY,
    CartId      BIGINT NOT NULL,
    VariantId   BIGINT NOT NULL,
    Qty         INT NOT NULL,
    UnitPrice   DECIMAL(18,2) NOT NULL,  -- قیمت لحظه افزودن به سبد (برای نمایش)
    CreatedAt   DATETIME2(3) NOT NULL CONSTRAINT DF_CartItems_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_CartItems_Carts    FOREIGN KEY (CartId)    REFERENCES dbo.Carts(Id) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_Variants FOREIGN KEY (VariantId) REFERENCES dbo.ProductVariants(Id),
    CONSTRAINT CK_CartItems_Qty CHECK (Qty > 0),
    CONSTRAINT CK_CartItems_UnitPrice CHECK (UnitPrice >= 0)
);
CREATE UNIQUE INDEX UX_CartItem_Cart_Variant ON dbo.CartItems(CartId, VariantId);

CREATE TABLE dbo.Coupons (
    Id           BIGINT IDENTITY PRIMARY KEY,
    Code         NVARCHAR(64) NOT NULL UNIQUE,
    Type         TINYINT NOT NULL,           -- 0=Amount,1=Percent
    Amount       DECIMAL(18,2) NOT NULL,
    MaxDiscount  DECIMAL(18,2) NULL,         -- سقف برای درصدی
    StartsAt     DATETIME2(3) NULL,
    ExpiresAt    DATETIME2(3) NULL,
    IsActive     BIT NOT NULL CONSTRAINT DF_Coupons_IsActive DEFAULT 1,
    CreatedAt    DATETIME2(3) NOT NULL CONSTRAINT DF_Coupons_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Coupons_Type CHECK (Type IN (0,1)),
    CONSTRAINT CK_Coupons_Amount CHECK (Amount >= 0)
);

CREATE TABLE dbo.CartCoupons (
    CartId    BIGINT NOT NULL,
    CouponId  BIGINT NOT NULL,
    AppliedAt DATETIME2(3) NOT NULL CONSTRAINT DF_CartCoupons_AppliedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CartCoupons PRIMARY KEY (CartId, CouponId),
    CONSTRAINT FK_CartCoupons_Carts   FOREIGN KEY (CartId)   REFERENCES dbo.Carts(Id)   ON DELETE CASCADE,
    CONSTRAINT FK_CartCoupons_Coupons FOREIGN KEY (CouponId) REFERENCES dbo.Coupons(Id) ON DELETE CASCADE
);

/* === 7) سفارش، آیتم، پرداخت، ارسال === */
CREATE TABLE dbo.Orders (
    Id             BIGINT IDENTITY PRIMARY KEY,
    UserId         BIGINT NOT NULL,
    OrderNo        NVARCHAR(32) NOT NULL UNIQUE, -- مثل ES-2025-000001
    Status         TINYINT NOT NULL CONSTRAINT DF_Orders_Status DEFAULT 0, -- 0=Pending,1=Paid,2=Shipped,3=Completed,4=Cancelled
    Currency       CHAR(3) NOT NULL CONSTRAINT DF_Orders_Currency DEFAULT 'EUR',
    Subtotal       DECIMAL(18,2) NOT NULL,
    DiscountTotal  DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_Discount DEFAULT 0,
    ShippingFee    DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_ShipFee DEFAULT 0,
    TaxTotal       DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_Tax DEFAULT 0,
    GrandTotal     DECIMAL(18,2) NOT NULL,
    ShippingAddressId BIGINT NULL,
    BillingAddressId  BIGINT NULL,
    CreatedAt      DATETIME2(3) NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt      DATETIME2(3) NOT NULL CONSTRAINT DF_Orders_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id),
    CONSTRAINT FK_Orders_ShippingAddress FOREIGN KEY (ShippingAddressId) REFERENCES dbo.Addresses(Id),
    CONSTRAINT FK_Orders_BillingAddress  FOREIGN KEY (BillingAddressId)  REFERENCES dbo.Addresses(Id),
    CONSTRAINT CK_Orders_Totals CHECK (Subtotal >= 0 AND DiscountTotal >= 0 AND ShippingFee >= 0 AND TaxTotal >= 0 AND GrandTotal >= 0)
);
CREATE INDEX IX_Orders_User_Status ON dbo.Orders(UserId, Status);

CREATE TABLE dbo.OrderItems (
    Id          BIGINT IDENTITY PRIMARY KEY,
    OrderId     BIGINT NOT NULL,
    VariantId   BIGINT NOT NULL,
    ProductName NVARCHAR(256) NOT NULL,   -- تثبیت برای تاریخچه
    Sku         NVARCHAR(64) NOT NULL,
    Qty         INT NOT NULL,
    UnitPrice   DECIMAL(18,2) NOT NULL,
    LineTotal   AS (CAST(Qty AS DECIMAL(18,2)) * UnitPrice) PERSISTED,
    CONSTRAINT FK_OrderItems_Orders   FOREIGN KEY (OrderId)   REFERENCES dbo.Orders(Id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Variants FOREIGN KEY (VariantId) REFERENCES dbo.ProductVariants(Id),
    CONSTRAINT CK_OrderItems_Qty CHECK (Qty > 0),
    CONSTRAINT CK_OrderItems_UnitPrice CHECK (UnitPrice >= 0)
);
CREATE INDEX IX_OrderItems_OrderId ON dbo.OrderItems(OrderId);

CREATE TABLE dbo.Payments (
    Id         BIGINT IDENTITY PRIMARY KEY,
    OrderId    BIGINT NOT NULL UNIQUE,  -- یک پرداخت برای نمونهٔ ساده
    Provider   NVARCHAR(64) NOT NULL,   -- Mock, Stripe, ...
    Amount     DECIMAL(18,2) NOT NULL,
    Status     TINYINT NOT NULL,        -- 0=Pending,1=Authorized,2=Captured,3=Failed,4=Refunded
    PaidAt     DATETIME2(3) NULL,
    Meta       NVARCHAR(2000) NULL,
    CreatedAt  DATETIME2(3) NOT NULL CONSTRAINT DF_Payments_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE,
    CONSTRAINT CK_Payments_Amount CHECK (Amount >= 0),
    CONSTRAINT CK_Payments_Status CHECK (Status IN (0,1,2,3,4))
);
CREATE INDEX IX_Payments_Status ON dbo.Payments(Status);

CREATE TABLE dbo.Shipments (
    Id           BIGINT IDENTITY PRIMARY KEY,
    OrderId      BIGINT NOT NULL UNIQUE,
    Carrier      NVARCHAR(64) NOT NULL,  -- DHL, UPS, ...
    TrackingCode NVARCHAR(128) NULL,
    Status       TINYINT NOT NULL,       -- 0=Pending,1=Shipped,2=Delivered,3=Returned
    ShippedAt    DATETIME2(3) NULL,
    DeliveredAt  DATETIME2(3) NULL,
    CreatedAt    DATETIME2(3) NOT NULL CONSTRAINT DF_Shipments_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Shipments_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE,
    CONSTRAINT CK_Shipments_Status CHECK (Status IN (0,1,2,3))
);

/* === 8) لاگ ممیزی (اختیاری ولی مفید برای رزومه) === */
CREATE TABLE dbo.AuditLog (
    Id        BIGINT IDENTITY PRIMARY KEY,
    UserId    BIGINT NULL,
    Action    NVARCHAR(64) NOT NULL,      -- CreateProduct, Checkout, etc.
    Entity    NVARCHAR(64) NULL,
    EntityId  BIGINT NULL,
    Meta      NVARCHAR(2000) NULL,
    At        DATETIME2(3) NOT NULL CONSTRAINT DF_AuditLog_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_AuditLog_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
);
CREATE INDEX IX_AuditLog_At ON dbo.AuditLog(At);

/* === 9) دادهٔ نمونه (Seed مختصر) === */
INSERT INTO dbo.Roles(Name) VALUES (N'Admin'), (N'Manager'), (N'Customer');

INSERT INTO dbo.Users(Email, PasswordHash, FullName)
VALUES (N'admin@example.com',   N'hashed_pwd_admin',   N'Admin User'),
       (N'alice@example.com',   N'hashed_pwd_alice',   N'Alice'),
       (N'bob@example.com',     N'hashed_pwd_bob',     N'Bob');

-- نقش‌ها
INSERT INTO dbo.UserRoles(UserId, RoleId)
SELECT u.Id, r.Id
FROM dbo.Users u CROSS JOIN dbo.Roles r
WHERE u.Email = N'admin@example.com' AND r.Name = N'Admin';

-- دسته‌ها
INSERT INTO dbo.Categories(Name, Slug) VALUES
(N'Electronics', N'electronics'),
(N'Books',       N'books'),
(N'Clothing',    N'clothing');

-- محصولات
INSERT INTO dbo.Products(Sku, Name, Slug, Description, BasePrice, Status)
VALUES (N'SKU-IPHONE13', N'iPhone 13', N'iphone-13', N'Apple smartphone', 799.00, 1),
       (N'SKU-BOOK-1984', N'1984 (Book)', N'book-1984', N'George Orwell', 9.99, 1);

-- روابط محصول-دسته
INSERT INTO dbo.ProductCategories(ProductId, CategoryId)
SELECT p.Id, c.Id FROM dbo.Products p JOIN dbo.Categories c
  ON (p.Slug = N'iphone-13' AND c.Slug = N'electronics')
UNION ALL
SELECT p.Id, c.Id FROM dbo.Products p JOIN dbo.Categories c
  ON (p.Slug = N'book-1984' AND c.Slug = N'books');

-- مدیای محصول
INSERT INTO dbo.ProductMedia(ProductId, Url, AltText, SortOrder)
SELECT Id, N'https://example.com/img/iphone13.jpg', N'iPhone 13 front', 0 FROM dbo.Products WHERE Slug=N'iphone-13';
INSERT INTO dbo.ProductMedia(ProductId, Url, AltText, SortOrder)
SELECT Id, N'https://example.com/img/1984.jpg', N'1984 book cover', 0 FROM dbo.Products WHERE Slug=N'book-1984';

-- واریانت‌ها
INSERT INTO dbo.ProductVariants(ProductId, Sku, AttributesJson, Price, Barcode, IsActive)
SELECT Id, N'VAR-IPH13-128-BLK', N'{"storage":"128GB","color":"black"}', 799.00, N'1111111111111', 1
FROM dbo.Products WHERE Slug=N'iphone-13';

INSERT INTO dbo.ProductVariants(ProductId, Sku, AttributesJson, Price, Barcode, IsActive)
SELECT Id, N'VAR-BOOK-1984-PBK', N'{"format":"paperback"}', 9.99, N'2222222222222', 1
FROM dbo.Products WHERE Slug=N'book-1984';

-- موجودی
INSERT INTO dbo.Inventory(VariantId, Quantity, Reserved)
SELECT Id, 50, 0 FROM dbo.ProductVariants WHERE Sku IN (N'VAR-IPH13-128-BLK', N'VAR-BOOK-1984-PBK');

-- کوپن نمونه
INSERT INTO dbo.Coupons(Code, Type, Amount, MaxDiscount, StartsAt, ExpiresAt, IsActive)
VALUES (N'WELCOME10', 1, 10.00, 50.00, SYSUTCDATETIME(), DATEADD(DAY, 90, SYSUTCDATETIME()), 1);

-- یک سبد نمونه
INSERT INTO dbo.Carts(UserId) SELECT Id FROM dbo.Users WHERE Email=N'alice@example.com';
DECLARE @CartId BIGINT = (SELECT TOP 1 Id FROM dbo.Carts ORDER BY Id DESC);
INSERT INTO dbo.CartItems(CartId, VariantId, Qty, UnitPrice)
SELECT @CartId, (SELECT Id FROM dbo.ProductVariants WHERE Sku=N'VAR-BOOK-1984-PBK'), 2, 9.99;

-- یک آدرس برای کاربر
INSERT INTO dbo.Addresses(UserId, Type, Line1, City, PostalCode, Country)
SELECT Id, 0, N'1 Main St', N'Luxembourg', N'12345', N'LU' FROM dbo.Users WHERE Email=N'alice@example.com';

