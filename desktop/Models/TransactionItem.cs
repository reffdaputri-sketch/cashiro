using System.ComponentModel.DataAnnotations.Schema;

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
