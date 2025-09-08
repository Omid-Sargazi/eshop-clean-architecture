using Eshop.Domain.Entities.Common;

namespace Eshop.Domain.Entities
{
    public class Role : AuditableEntity
    {
        public string Name { get; set; } = string.Empty;

        //Navogation
        public ICollection<User> Users { get; set; } = new List<User>();
    }
}