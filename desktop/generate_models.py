import os

models_dir = "Models"
data_dir = "Data"

models = {
    "BaseEntity.cs": """using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KioslyDesktop.Models
{
    public abstract class BaseEntity
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id")]
        public int Id { get; set; }
        
        [Column("is_synced")]
        public int IsSynced { get; set; } = 0;
    }
}
""",
    "Product.cs": """using System;
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
""",
    "Transaction.cs": """using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace KioslyDesktop.Models
{
    [Table("transactions")]
    public class Transaction : BaseEntity
    {
        [Column("total_amount")]
        public double TotalAmount { get; set; }

        [Column("paid_amount")]
        public double PaidAmount { get; set; }

        [Column("created_at")]
        public string CreatedAt { get; set; } = DateTime.UtcNow.ToString("O");

        [Column("customer_id")]
        public int? CustomerId { get; set; }

        [Column("payment_method")]
        public string? PaymentMethod { get; set; }

        [Column("shift_id")]
        public int? ShiftId { get; set; }

        [Column("status")]
        public string Status { get; set; } = "Selesai";

        [Column("tax_amount")]
        public double TaxAmount { get; set; } = 0.0;

        [Column("service_charge_amount")]
        public double ServiceChargeAmount { get; set; } = 0.0;

        [Column("cashier_name")]
        public string? CashierName { get; set; }

        [Column("tax_percentage")]
        public double? TaxPercentage { get; set; }
    }
}
""",
    "TransactionItem.cs": """using System.ComponentModel.DataAnnotations.Schema;

namespace KioslyDesktop.Models
{
    [Table("transaction_items")]
    public class TransactionItem : BaseEntity
    {
        [Column("transaction_id")]
        public int TransactionId { get; set; }

        [Column("product_id")]
        public int ProductId { get; set; }

        [Column("quantity")]
        public int Quantity { get; set; }

        [Column("price_at_sale")]
        public double PriceAtSale { get; set; }

        [Column("cost_at_sale")]
        public double CostAtSale { get; set; } = 0.0;

        [Column("returned_qty")]
        public int ReturnedQty { get; set; } = 0;
    }
}
"""
}

app_db_context = """using Microsoft.EntityFrameworkCore;
using KioslyDesktop.Models;
using System.IO;
using System;

namespace KioslyDesktop.Data
{
    public class AppDbContext : DbContext
    {
        public DbSet<Product> Products { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<TransactionItem> TransactionItems { get; set; }

        public string DbPath { get; }

        public AppDbContext()
        {
            var folder = Environment.SpecialFolder.LocalApplicationData;
            var path = Environment.GetFolderPath(folder);
            DbPath = System.IO.Path.Join(path, "KioslyDesktop", "kiosly.db");
            
            var dir = System.IO.Path.GetDirectoryName(DbPath);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }
        }

        protected override void OnConfiguring(DbContextOptionsBuilder options)
            => options.UseSqlite($"Data Source={DbPath}");
    }
}
"""

for name, content in models.items():
    with open(os.path.join(models_dir, name), "w") as f:
        f.write(content)

with open(os.path.join(data_dir, "AppDbContext.cs"), "w") as f:
    f.write(app_db_context)

print("Files generated successfully.")
