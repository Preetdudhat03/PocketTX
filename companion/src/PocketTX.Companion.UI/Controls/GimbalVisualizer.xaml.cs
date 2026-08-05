using System.Windows;
using System.Windows.Controls;

namespace PocketTX.Companion.UI.Controls;

public partial class GimbalVisualizer : UserControl
{
    public static readonly DependencyProperty XValueProperty =
        DependencyProperty.Register(nameof(XValue), typeof(float), typeof(GimbalVisualizer),
            new PropertyMetadata(0.0f, OnAxisChanged));

    public static readonly DependencyProperty YValueProperty =
        DependencyProperty.Register(nameof(YValue), typeof(float), typeof(GimbalVisualizer),
            new PropertyMetadata(0.0f, OnAxisChanged));

    public static readonly DependencyProperty TitleProperty =
        DependencyProperty.Register(nameof(Title), typeof(string), typeof(GimbalVisualizer),
            new PropertyMetadata("GIMBAL", OnTitleChanged));

    public float XValue
    {
        get => (float)GetValue(XValueProperty);
        set => SetValue(XValueProperty, value);
    }

    public float YValue
    {
        get => (float)GetValue(YValueProperty);
        set => SetValue(YValueProperty, value);
    }

    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    public GimbalVisualizer()
    {
        InitializeComponent();
        Loaded += (s, e) => UpdateDotPosition();
        SizeChanged += (s, e) => UpdateDotPosition();
    }

    private static void OnAxisChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is GimbalVisualizer control)
        {
            control.UpdateDotPosition();
        }
    }

    private static void OnTitleChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is GimbalVisualizer control && e.NewValue is string title)
        {
            control.TitleLabel.Text = title;
        }
    }

    private void UpdateDotPosition()
    {
        double width = ContainerGrid.ActualWidth;
        double height = ContainerGrid.ActualHeight;

        if (width <= 0 || height <= 0) return;

        double centerX = width / 2.0;
        double centerY = height / 2.0;

        // XValue: -1.0 to 1.0 -> left to right
        // YValue: -1.0 to 1.0 -> bottom to top (inverted Y for Canvas coordinate space)
        double posX = centerX + (XValue * (centerX - 16.0));
        double posY = centerY - (YValue * (centerY - 16.0));

        Canvas.SetLeft(StickDot, posX - 9.0);
        Canvas.SetTop(StickDot, posY - 9.0);
    }
}
