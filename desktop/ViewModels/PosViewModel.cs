using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using KioslyDesktop.Data;
using KioslyDesktop.Models;
using Microsoft.EntityFrameworkCore;

namespace KioslyDesktop.ViewModels
{
    public partial class PosViewModel : ObservableObject
    {
        [ObservableProperty]
        private ObservableCollection<Product> _products = new();

        [ObservableProperty]
        private ObservableCollection<CartItem> _cart = new();

        [ObservableProperty]
        private string _searchQuery = string.Empty;

        public double TotalAmount => Cart.Sum(item => item.Total);

        public PosViewModel()
        {
            LoadProducts();
        }

        private void LoadProducts()
        {
            if (System.ComponentModel.DesignerProperties.GetIsInDesignMode(new System.Windows.DependencyObject()))
                return;

            using var db = new AppDbContext();
            var allProducts = db.Products.Where(p => p.IsDeleted == 0).ToList();
            
            // Mock data if db is empty
            if (!allProducts.Any())
            {
                allProducts.Add(new Product { Name = "Es Teh Manis", Price = 5000, Stock = 100 });
                allProducts.Add(new Product { Name = "Nasi Goreng", Price = 20000, Stock = 50 });
                
                db.Products.AddRange(allProducts);
                db.SaveChanges();
            }

            Products = new ObservableCollection<Product>(allProducts);
        }

        [RelayCommand]
        private void AddToCart(Product product)
        {
            if (product == null) return;

            var existingItem = Cart.FirstOrDefault(c => c.Product.Id == product.Id);
            if (existingItem != null)
            {
                existingItem.Quantity++;
            }
            else
            {
                Cart.Add(new CartItem { Product = product, Quantity = 1 });
            }
            OnPropertyChanged(nameof(TotalAmount));
        }

        [RelayCommand]
        private void ProcessPayment()
        {
            if (!Cart.Any()) return;

            using var db = new AppDbContext();
            
            var transaction = new Transaction
            {
                TotalAmount = TotalAmount,
                PaidAmount = TotalAmount,
                Status = "Selesai",
                IsSynced = 0 // Will be synced by SyncWorker
            };

            db.Transactions.Add(transaction);
            db.SaveChanges(); // Need Id for items

            foreach (var item in Cart)
            {
                db.TransactionItems.Add(new TransactionItem
                {
                    TransactionId = transaction.Id,
                    ProductId = item.Product.Id,
                    Quantity = item.Quantity,
                    PriceAtSale = item.Product.Price
                });
            }

            db.SaveChanges();

            // Clear cart
            Cart.Clear();
            OnPropertyChanged(nameof(TotalAmount));
            
            // Here we would normally trigger PrinterService
        }

        partial void OnSearchQueryChanged(string value)
        {
            using var db = new AppDbContext();
            if (string.IsNullOrWhiteSpace(value))
            {
                var allProducts = db.Products.Where(p => p.IsDeleted == 0).ToList();
                Products = new ObservableCollection<Product>(allProducts);
            }
            else
            {
                var filtered = db.Products
                    .Where(p => p.IsDeleted == 0 && (p.Name.ToLower().Contains(value.ToLower()) || (p.Code != null && p.Code == value)))
                    .ToList();
                Products = new ObservableCollection<Product>(filtered);
                
                // Wedge barcode scanner logic: if exactly 1 matched by code, auto add to cart
                if (filtered.Count == 1 && filtered.First().Code == value)
                {
                    AddToCart(filtered.First());
                    SearchQuery = string.Empty; // Reset for next scan
                }
            }
        }
    }
}
