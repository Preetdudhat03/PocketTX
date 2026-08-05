using PocketTX.Companion.VirtualController.Math;
using Xunit;

namespace PocketTX.Companion.Tests.VirtualController;

public class AxisTransformerTests
{
    [Fact]
    public void ApplyDeadband_InputBelowThreshold_ReturnsZero()
    {
        float result = AxisTransformer.ApplyDeadband(0.015f, 0.02f);
        Assert.Equal(0.0f, result);
    }

    [Fact]
    public void ApplyDeadband_InputAboveThreshold_ScalesCorrectly()
    {
        float result = AxisTransformer.ApplyDeadband(0.51f, 0.02f);
        Assert.True(result > 0.0f);
        Assert.True(result <= 1.0f);
    }

    [Fact]
    public void ApplyExpo_ZeroExpo_ReturnsInputUnchanged()
    {
        float input = 0.5f;
        float result = AxisTransformer.ApplyExpo(input, 0.0f);
        Assert.Equal(input, result, precision: 4);
    }

    [Fact]
    public void ApplyExpo_PositiveExpo_SoftensCenter()
    {
        float input = 0.5f;
        float result = AxisTransformer.ApplyExpo(input, 0.20f);
        Assert.True(result < input);
    }
}
