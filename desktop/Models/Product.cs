using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace KioslyDesktop.Models
{
    [Table("products")]
    public class Product : BaseEntity
    {
        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Column("price")]
        public double Price { get; set; }

        [Column("stock")]
        public int Stock { get; set; }

        [Column("code")]
        public string? Code { get; set; }

        [Column("image_path")]
        public string? ImagePath { get; set; }

        [Column("created_at")]
        public string CreatedAt { get; set; } = DateTime.UtcNow.ToString("O");

        [Column("cost_price")]
        public double CostPrice { get; set; } = 0.0;

        [Column("category")]
        public string? Category { get; set; }

        [Column("min_stock")]
        public int MinStock { get; set; } = 5;

        [Column("is_online")]
        public int IsOnline { get; set; } = 0;

        [Column("weight")]
        public int Weight { get; set; } = 0;

        [Column("is_deleted")]
        public int IsDeleted { get; set; } = 0;
    }
}
