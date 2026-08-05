using System.Windows;
using Microsoft.Extensions.DependencyInjection;
using PocketTX.Companion.UI.ViewModels;

namespace PocketTX.Companion.UI.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        if (Application.Current is App app)
        {
            DataContext = app.Services.GetRequiredService<MainViewModel>();
        }
    }

    public MainWindow(MainViewModel viewModel) : this()
    {
        DataContext = viewModel;
    }
}
