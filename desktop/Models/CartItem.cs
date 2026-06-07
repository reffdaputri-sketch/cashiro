using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace KioslyDesktop.Models
{
    public class CartItem : INotifyPropertyChanged
    {
        private int _quantity;

        public Product Product { get; set; }

        public int Quantity
        {
            get => _quantity;
            set
            {
                if (_quantity != value)
                {
                    _quantity = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(Total));
                }
            }
        }

        public double Total => Product.Price * Quantity;

        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
