using System.Collections.ObjectModel;
using System.Linq;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using KioslyDesktop.Data;
using KioslyDesktop.Models;

namespace KioslyDesktop.ViewModels
{
    public partial class ProductListViewModel : ObservableObject
    {
        [ObservableProperty]
        private ObservableCollection<Product> _products = new();

        [ObservableProperty]
        private Product? _selectedProduct;

        public ProductListViewModel()
        {
            LoadProducts();
        }

        private void LoadProducts()
        {
            if (System.ComponentModel.DesignerProperties.GetIsInDesignMode(new System.Windows.DependencyObject()))
                return;

            using var db = new AppDbContext();
            var allProducts = db.Products.Where(p => p.IsDeleted == 0).ToList();
            Products = new ObservableCollection<Product>(allProducts);
        }

        [RelayCommand]
        private void AddNewProduct()
        {
            // Simple logic for adding a new product
            var newProduct = new Product
            {
                Name = "Produk Baru",
                Price = 0,
                Stock = 0,
                IsSynced = 0 // Needs sync to cloud
            };

            using var db = new AppDbContext();
            db.Products.Add(newProduct);
            db.SaveChanges();

            Products.Add(newProduct);
            SelectedProduct = newProduct;
        }

        [RelayCommand]
        private void SaveProduct()
        {
            if (SelectedProduct == null) return;

            using var db = new AppDbContext();
            var product = db.Products.FirstOrDefault(p => p.Id == SelectedProduct.Id);
            if (product != null)
            {
                product.Name = SelectedProduct.Name;
                product.Price = SelectedProduct.Price;
                product.Stock = SelectedProduct.Stock;
                product.Code = SelectedProduct.Code;
                product.Category = SelectedProduct.Category;
                product.IsSynced = 0; // Needs sync to cloud

                db.SaveChanges();
            }
        }

        [RelayCommand]
        private void DeleteProduct()
        {
            if (SelectedProduct == null) return;

            using var db = new AppDbContext();
            var product = db.Products.FirstOrDefault(p => p.Id == SelectedProduct.Id);
            if (product != null)
            {
                product.IsDeleted = 1;
                product.IsSynced = 0;
                db.SaveChanges();

                Products.Remove(SelectedProduct);
                SelectedProduct = null;
            }
        }
    }
}
