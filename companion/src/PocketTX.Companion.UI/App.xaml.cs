using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace PocketTX.Companion.UI;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var win = new Window
        {
            Title = "PocketTX Diagnostic Test Window",
            Width = 800,
            Height = 600,
            WindowStartupLocation = WindowStartupLocation.CenterScreen,
            Background = Brushes.DarkBlue,
            Content = new Grid
            {
                Background = Brushes.DarkBlue,
                Children =
                {
                    new TextBlock
                    {
                        Text = "POCKET TX DIAGNOSTIC WINDOW WORKING!",
                        Foreground = Brushes.Yellow,
                        FontSize = 28,
                        FontWeight = FontWeights.Bold,
                        HorizontalAlignment = HorizontalAlignment.Center,
                        VerticalAlignment = VerticalAlignment.Center
                    }
                }
            }
        };

        win.Show();
    }
}
