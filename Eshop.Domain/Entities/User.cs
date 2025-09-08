using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class User : AuditableEntity
    {
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;

        //Navigation
        public ICollection<Role> Roles { get; set; } = new List<Role>();
        public ICollection<Cart> Carts { get; set; } = new List<Cart>();
        public ICollection<Order> Orders { get; set; } = new List<Order>();   
    }
}