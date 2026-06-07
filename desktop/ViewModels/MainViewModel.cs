using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace KioslyDesktop.ViewModels
{
    public partial class MainViewModel : ObservableObject
    {
        [ObservableProperty]
        private object _currentView;

        private readonly PosViewModel _posViewModel;
        private readonly ProductListViewModel _productListViewModel;

        public MainViewModel()
        {
            _posViewModel = new PosViewModel();
            _productListViewModel = new ProductListViewModel();
            CurrentView = _posViewModel;
        }

        [RelayCommand]
        private void NavigateToPos()
        {
            CurrentView = _posViewModel;
        }

        [RelayCommand]
        private void NavigateToProducts()
        {
            CurrentView = _productListViewModel;
        }
    }
}
