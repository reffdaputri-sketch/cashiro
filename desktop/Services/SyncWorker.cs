using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using KioslyDesktop.Data;

namespace KioslyDesktop.Services
{
    public class SyncWorker : BackgroundService
    {
        private readonly ApiService _apiService;
        private readonly AuthService _authService;

        public SyncWorker()
        {
            _apiService = new ApiService();
            _authService = new AuthService();
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await PerformSyncAsync();
                    await PullMasterDataAsync();
                }
                catch (Exception)
                {
                    // Fail silently for background sync
                }
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }

        private async Task PerformSyncAsync()
        {
            var licenseKey = _authService.GetLicenseKey();
            if (string.IsNullOrEmpty(licenseKey)) return;

            using var db = new AppDbContext();
            
            var unsyncedProducts = await db.Products.Where(p => p.IsSynced == 0).ToListAsync();
            if (unsyncedProducts.Any())
            {
                // Mockup upload process, marked as synced afterwards
                foreach (var p in unsyncedProducts) p.IsSynced = 1;
                await db.SaveChangesAsync();
            }
            
            var unsyncedTransactions = await db.Transactions.Where(t => t.IsSynced == 0).ToListAsync();
            if (unsyncedTransactions.Any())
            {
                foreach (var t in unsyncedTransactions) t.IsSynced = 1;
                await db.SaveChangesAsync();
            }
        }

        private async Task PullMasterDataAsync()
        {
            var licenseKey = _authService.GetLicenseKey();
            if (string.IsNullOrEmpty(licenseKey)) return;

            // In a real app, this calls _apiService.GetProductsAsync()
            // For now, we mock pulling a new product if it doesn't exist.
            using var db = new AppDbContext();
            
            bool hasAyamBakar = await db.Products.AnyAsync(p => p.Name == "Ayam Bakar (Sync)");
            if (!hasAyamBakar)
            {
                db.Products.Add(new Models.Product
                {
                    Name = "Ayam Bakar (Sync)",
                    Price = 25000,
                    Stock = 20,
                    Category = "Makanan",
                    IsSynced = 1 // already synced from server
                });
                await db.SaveChangesAsync();
            }
        }
    }
}
