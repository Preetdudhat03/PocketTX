using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace PocketTX.Companion.UI.Controls;

public sealed class LatencySparklineCanvas : Canvas
{
    private readonly Queue<double> _values = new();
    private const int MaxPoints = 50;

    public static readonly DependencyProperty CurrentLatencyProperty =
        DependencyProperty.Register(nameof(CurrentLatency), typeof(double), typeof(LatencySparklineCanvas),
            new PropertyMetadata(0.0, OnLatencyChanged));

    public double CurrentLatency
    {
        get => (double)GetValue(CurrentLatencyProperty);
        set => SetValue(CurrentLatencyProperty, value);
    }

    private static void OnLatencyChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is LatencySparklineCanvas canvas && e.NewValue is double latency)
        {
            canvas.AddLatencyValue(latency);
        }
    }

    public void AddLatencyValue(double latency)
    {
        _values.Enqueue(latency);
        while (_values.Count > MaxPoints)
        {
            _values.Dequeue();
        }
        InvalidateVisual();
    }

    protected override void OnRender(DrawingContext dc)
    {
        base.OnRender(dc);

        double width = ActualWidth;
        double height = ActualHeight;

        if (width <= 0 || height <= 0 || _values.Count < 2) return;

        Brush accentBrush = (Brush)TryFindResource("PrimaryAccentBrush") ?? Brushes.DodgerBlue;
        Pen pen = new(accentBrush, 2.0);

        double maxVal = System.Math.Max(5.0, _values.Max());
        double stepX = width / (MaxPoints - 1);

        double[] vals = _values.ToArray();
        Point[] points = new Point[vals.Length];

        for (int i = 0; i < vals.Length; i++)
        {
            double x = i * stepX;
            double normalizedY = vals[i] / maxVal;
            double y = height - (normalizedY * (height - 4.0));
            points[i] = new Point(x, y);
        }

        for (int i = 0; i < points.Length - 1; i++)
        {
            dc.DrawLine(pen, points[i], points[i + 1]);
        }
    }
}
