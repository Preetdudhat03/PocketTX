using System.Windows;
using PocketTX.Companion.UI.ViewModels;

namespace PocketTX.Companion.UI.Views;

public partial class MainWindow : Window
{
    public MainWindow(MainViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
    }
}
