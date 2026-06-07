using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KioslyDesktop.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "products",
                columns: table => new
                {
                    id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    name = table.Column<string>(type: "TEXT", nullable: false),
                    price = table.Column<double>(type: "REAL", nullable: false),
                    stock = table.Column<int>(type: "INTEGER", nullable: false),
                    code = table.Column<string>(type: "TEXT", nullable: true),
                    image_path = table.Column<string>(type: "TEXT", nullable: true),
                    created_at = table.Column<string>(type: "TEXT", nullable: false),
                    cost_price = table.Column<double>(type: "REAL", nullable: false),
                    category = table.Column<string>(type: "TEXT", nullable: true),
                    min_stock = table.Column<int>(type: "INTEGER", nullable: false),
                    is_online = table.Column<int>(type: "INTEGER", nullable: false),
                    weight = table.Column<int>(type: "INTEGER", nullable: false),
                    is_deleted = table.Column<int>(type: "INTEGER", nullable: false),
                    is_synced = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_products", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "transaction_items",
                columns: table => new
                {
                    id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    transaction_id = table.Column<int>(type: "INTEGER", nullable: false),
                    product_id = table.Column<int>(type: "INTEGER", nullable: false),
                    quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    price_at_sale = table.Column<double>(type: "REAL", nullable: false),
                    cost_at_sale = table.Column<double>(type: "REAL", nullable: false),
                    returned_qty = table.Column<int>(type: "INTEGER", nullable: false),
                    is_synced = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_transaction_items", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "transactions",
                columns: table => new
                {
                    id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    total_amount = table.Column<double>(type: "REAL", nullable: false),
                    paid_amount = table.Column<double>(type: "REAL", nullable: false),
                    created_at = table.Column<string>(type: "TEXT", nullable: false),
                    customer_id = table.Column<int>(type: "INTEGER", nullable: true),
                    payment_method = table.Column<string>(type: "TEXT", nullable: true),
                    shift_id = table.Column<int>(type: "INTEGER", nullable: true),
                    status = table.Column<string>(type: "TEXT", nullable: false),
                    tax_amount = table.Column<double>(type: "REAL", nullable: false),
                    service_charge_amount = table.Column<double>(type: "REAL", nullable: false),
                    cashier_name = table.Column<string>(type: "TEXT", nullable: true),
                    tax_percentage = table.Column<double>(type: "REAL", nullable: true),
                    is_synced = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_transactions", x => x.id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "products");

            migrationBuilder.DropTable(
                name: "transaction_items");

            migrationBuilder.DropTable(
                name: "transactions");
        }
    }
}
