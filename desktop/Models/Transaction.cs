using System;
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
