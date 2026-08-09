using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace PocketTX.Companion.UI.Controls;

public partial class GimbalVisualizer : UserControl
{
    private bool _isDragging;

    public static readonly DependencyProperty XValueProperty =
        DependencyProperty.Register(nameof(XValue), typeof(float), typeof(GimbalVisualizer),
            new FrameworkPropertyMetadata(0.0f, FrameworkPropertyMetadataOptions.BindsTwoWayByDefault, OnAxisChanged));

    public static readonly DependencyProperty YValueProperty =
        DependencyProperty.Register(nameof(YValue), typeof(float), typeof(GimbalVisualizer),
            new FrameworkPropertyMetadata(0.0f, FrameworkPropertyMetadataOptions.BindsTwoWayByDefault, OnAxisChanged));

    public static readonly DependencyProperty TitleProperty =
        DependencyProperty.Register(nameof(Title), typeof(string), typeof(GimbalVisualizer),
            new PropertyMetadata("GIMBAL", OnTitleChanged));

    public static readonly DependencyProperty IsInteractiveProperty =
        DependencyProperty.Register(nameof(IsInteractive), typeof(bool), typeof(GimbalVisualizer),
            new PropertyMetadata(true));

    public static readonly DependencyProperty IsSpringLoadedProperty =
        DependencyProperty.Register(nameof(IsSpringLoaded), typeof(bool), typeof(GimbalVisualizer),
            new PropertyMetadata(true));

    public static readonly DependencyProperty DefaultYValueProperty =
        DependencyProperty.Register(nameof(DefaultYValue), typeof(float), typeof(GimbalVisualizer),
            new PropertyMetadata(0.0f));

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

    public bool IsInteractive
    {
        get => (bool)GetValue(IsInteractiveProperty);
        set => SetValue(IsInteractiveProperty, value);
    }

    public bool IsSpringLoaded
    {
        get => (bool)GetValue(IsSpringLoadedProperty);
        set => SetValue(IsSpringLoadedProperty, value);
    }

    public float DefaultYValue
    {
        get => (float)GetValue(DefaultYValueProperty);
        set => SetValue(DefaultYValueProperty, value);
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
        // YValue: -1.0 to 1.0 -> bottom to top
        double posX = centerX + (XValue * (centerX - 16.0));
        double posY = centerY - (YValue * (centerY - 16.0));

        Canvas.SetLeft(StickDot, posX - 10.0);
        Canvas.SetTop(StickDot, posY - 10.0);

        // Update vector line from center to dot
        StickVectorLine.X1 = centerX;
        StickVectorLine.Y1 = centerY;
        StickVectorLine.X2 = posX;
        StickVectorLine.Y2 = posY;

        // Update numeric badge
        if (PosText != null)
        {
            PosText.Text = $"{XValue:+0.00;-0.00;0.00}, {YValue:+0.00;-0.00;0.00}";
        }
    }

    private void ContainerGrid_MouseDown(object sender, MouseButtonEventArgs e)
    {
        if (!IsInteractive) return;

        _isDragging = true;
        ContainerGrid.CaptureMouse();
        UpdateAxesFromMouse(e.GetPosition(ContainerGrid));
    }

    private void ContainerGrid_MouseMove(object sender, MouseEventArgs e)
    {
        if (!_isDragging || !IsInteractive) return;

        UpdateAxesFromMouse(e.GetPosition(ContainerGrid));
    }

    private void ContainerGrid_MouseUp(object sender, MouseButtonEventArgs e)
    {
        EndDrag();
    }

    private void ContainerGrid_MouseLeave(object sender, MouseEventArgs e)
    {
        if (_isDragging && IsSpringLoaded)
        {
            EndDrag();
        }
    }

    private void EndDrag()
    {
        if (!_isDragging) return;

        _isDragging = false;
        ContainerGrid.ReleaseMouseCapture();

        if (IsSpringLoaded)
        {
            XValue = 0.0f;
            YValue = DefaultYValue;
        }
    }

    private void UpdateAxesFromMouse(Point pos)
    {
        double width = ContainerGrid.ActualWidth;
        double height = ContainerGrid.ActualHeight;

        if (width <= 0 || height <= 0) return;

        double centerX = width / 2.0;
        double centerY = height / 2.0;
        double maxRadius = Math.Min(centerX, centerY) - 16.0;

        double normX = (pos.X - centerX) / maxRadius;
        double normY = (centerY - pos.Y) / maxRadius;

        XValue = (float)Math.Clamp(normX, -1.0, 1.0);
        YValue = (float)Math.Clamp(normY, -1.0, 1.0);
    }
}

